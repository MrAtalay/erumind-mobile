import 'package:flutter/material.dart';

import '../../data/continent_defs.dart';
import '../../data/world_shapes.dart';
import '../../logic/map_game_state.dart';

class WorldMapPainter extends CustomPainter {
  final Map<String, Owner> ownership;
  final Set<String> reachable;
  final String? highlighted;
  final bool dimUnreachable;

  // Muted faction colours — calm emerald / clay rose instead of neon.
  static const _playerColor = Color(0xFF4FB68A);
  static const _aiColor = Color(0xFFC97A78);

  const WorldMapPainter({
    required this.ownership,
    required this.reachable,
    this.highlighted,
    this.dimUnreachable = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = mapRect(size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Ocean panel — calm slate-blue, a touch lighter so it reads clean
    // (airy) rather than murky.
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B4055), Color(0xFF0E2533)],
      ).createShader(rect);
    canvas.drawRRect(rrect, oceanPaint);

    // Clip landmasses to the rounded ocean panel.
    canvas.save();
    canvas.clipRRect(rrect);

    // Pass 1 — soft gold halo behind reachable / highlighted continents. A
    // glow reads as "you can attack here" without busy internal outlines.
    for (final shape in kWorldShapes) {
      final isTarget =
          reachable.contains(shape.continentId) || shape.continentId == highlighted;
      if (!isTarget) continue;
      final strong = shape.continentId == highlighted;
      canvas.drawPath(
        _shapePath(shape.points, rect),
        Paint()
          ..color = const Color(0xFFEBCF86).withValues(alpha: strong ? 0.65 : 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // Pass 2 — flat continent fills + a clean continent outline. The shapes are
    // dissolved per continent, so the outline traces just the continent edge —
    // no internal country borders.
    for (final shape in kWorldShapes) {
      final owner = ownership[shape.continentId] ?? Owner.neutral;
      final def = continentById(shape.continentId);
      final isTarget =
          reachable.contains(shape.continentId) || shape.continentId == highlighted;
      final isOwned = owner != Owner.neutral;

      final fill = switch (owner) {
        Owner.player  => _playerColor,
        Owner.ai      => _aiColor,
        Owner.neutral => def?.color ?? const Color(0xFF888888),
      };

      final double opacity = (isOwned || isTarget)
          ? 0.97
          : dimUnreachable
              ? 0.55
              : 0.92;

      final path = _shapePath(shape.points, rect);
      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );

      // Continent outline.
      final Color outline;
      double outlineWidth;
      if (isTarget) {
        outline = const Color(0xFFE6C878);
        outlineWidth = 1.6;
      } else if (dimUnreachable && !isOwned) {
        outline = Colors.white.withValues(alpha: 0.16);
        outlineWidth = 0.9;
      } else {
        outline = Colors.white.withValues(alpha: isOwned ? 0.42 : 0.32);
        outlineWidth = 1.1;
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Vignette — gentle edge darkening for depth (lighter than before).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Colors.transparent, Colors.black.withAlpha(46)],
          stops: const [0.7, 1.0],
        ).createShader(rect),
    );

    canvas.restore(); // end clip

    // Panel frame — subtle dark edge against the screen background.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withAlpha(55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Labels — one per continent, at the centroid of its largest polygon.
    _labelCentroids.forEach((contId, normCentroid) {
      final owner = ownership[contId] ?? Owner.neutral;
      final def = continentById(contId);
      if (def == null) return;
      final isHighlighted = contId == highlighted;
      final isReachable = reachable.contains(contId);
      final visible = isHighlighted || owner != Owner.neutral || isReachable;
      final center = Offset(
        rect.left + normCentroid.dx * rect.width,
        rect.top + normCentroid.dy * rect.height,
      );
      _drawLabel(
        canvas,
        def.name,
        center,
        Colors.white.withValues(alpha: visible ? 0.95 : 0.72),
        rect.width * 0.18,
      );
    });
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: 0.3,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 4)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  static Path _shapePath(List<Offset> pts, Rect rect) {
    final path = Path();
    if (pts.isEmpty) return path;
    Offset px(Offset n) => Offset(rect.left + n.dx * rect.width, rect.top + n.dy * rect.height);
    final first = px(pts.first);
    path.moveTo(first.dx, first.dy);
    for (final p in pts.skip(1)) {
      final q = px(p);
      path.lineTo(q.dx, q.dy);
    }
    path.close();
    return path;
  }

  /// The rect (within [size]) the world map occupies, preserving aspect ratio.
  static Rect mapRect(Size size) {
    final dispW = size.width <= size.height * kMapAspect
        ? size.width
        : size.height * kMapAspect;
    final dispH = dispW / kMapAspect;
    final left = (size.width - dispW) / 2;
    final top = (size.height - dispH) / 2;
    return Rect.fromLTWH(left, top, dispW, dispH);
  }

  /// Returns the continent id at [position] within [size], or null.
  static String? continentAt(Offset position, Size size) {
    final rect = mapRect(size);
    // Reverse so smaller islands drawn later win ties; continents overlap rarely.
    for (final shape in kWorldShapes.reversed) {
      if (_shapePath(shape.points, rect).contains(position)) {
        return shape.continentId;
      }
    }
    return null;
  }

  /// Forgiving fallback for a tap that missed every polygon: the nearest
  /// [candidates] continent whose label centroid is within [maxDist] pixels.
  static String? nearestContinentAt(
    Offset position,
    Size size, {
    required Set<String> candidates,
    double maxDist = 40,
  }) {
    if (candidates.isEmpty) return null;
    final rect = mapRect(size);
    String? best;
    var bestD = maxDist;
    for (final id in candidates) {
      final c = _labelCentroids[id];
      if (c == null) continue;
      final px = Offset(rect.left + c.dx * rect.width, rect.top + c.dy * rect.height);
      final d = (px - position).distance;
      if (d < bestD) {
        bestD = d;
        best = id;
      }
    }
    return best;
  }

  @override
  bool shouldRepaint(WorldMapPainter old) =>
      old.ownership != ownership ||
      old.reachable != reachable ||
      old.highlighted != highlighted ||
      old.dimUnreachable != dimUnreachable;
}

/// Centroid (normalised 0..1) of each continent's largest polygon, for labels.
final Map<String, Offset> _labelCentroids = _computeLabelCentroids();

Map<String, Offset> _computeLabelCentroids() {
  final bestArea = <String, double>{};
  final result = <String, Offset>{};
  for (final shape in kWorldShapes) {
    final area = _polyArea(shape.points);
    if (area > (bestArea[shape.continentId] ?? 0)) {
      bestArea[shape.continentId] = area;
      result[shape.continentId] = _centroid(shape.points);
    }
  }
  return result;
}

double _polyArea(List<Offset> pts) {
  double a = 0;
  for (var i = 0; i < pts.length; i++) {
    final p1 = pts[i];
    final p2 = pts[(i + 1) % pts.length];
    a += p1.dx * p2.dy - p2.dx * p1.dy;
  }
  return a.abs() / 2;
}

Offset _centroid(List<Offset> pts) {
  double cx = 0, cy = 0;
  for (final p in pts) {
    cx += p.dx;
    cy += p.dy;
  }
  return Offset(cx / pts.length, cy / pts.length);
}
