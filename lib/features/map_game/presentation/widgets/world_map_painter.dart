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

    // Ocean panel — deep, desaturated slate-navy (calm, low eye strain).
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF143240), Color(0xFF0A1A24)],
      ).createShader(rect);
    canvas.drawRRect(rrect, oceanPaint);

    // Clip landmasses to the rounded ocean panel.
    canvas.save();
    canvas.clipRRect(rrect);

    // Draw landmasses, grouped by continent so colours read as one mass.
    for (final shape in kWorldShapes) {
      final owner = ownership[shape.continentId] ?? Owner.neutral;
      final def = continentById(shape.continentId);
      final isHighlighted = shape.continentId == highlighted;
      final isReachable = reachable.contains(shape.continentId);
      final isOwned = owner != Owner.neutral;

      final fill = switch (owner) {
        Owner.player  => _playerColor,
        Owner.ai      => _aiColor,
        Owner.neutral => def?.color ?? const Color(0xFF888888),
      };

      double opacity;
      if (isHighlighted) {
        opacity = 1.0;
      } else if (isOwned) {
        opacity = 0.94;
      } else if (isReachable) {
        opacity = 0.90;
      } else if (dimUnreachable) {
        opacity = 0.45;
      } else {
        opacity = 0.86;
      }

      final path = _shapePath(shape.points, rect);

      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );

      // Per-polygon border. Reachable continents get a soft gold edge so the
      // player sees where they may attack; everything else uses a faint dark
      // coastline line (calmer than bright white grid lines).
      final isTarget = isHighlighted || isReachable;
      canvas.drawPath(
        path,
        Paint()
          ..color = isTarget ? const Color(0xFFE6C878) : Colors.black.withAlpha(38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isTarget ? 1.4 : 0.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Vignette — subtle darkening toward the edges adds depth and focus.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withAlpha(70)],
          stops: const [0.62, 1.0],
        ).createShader(rect),
    );

    canvas.restore(); // end clip

    // Panel frame — subtle dark edge against the screen background.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.black.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
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
        Colors.white.withValues(alpha: visible ? 0.92 : 0.62),
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
