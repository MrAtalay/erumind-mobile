import 'package:flutter/material.dart';

import '../../data/continent_defs.dart';
import '../../data/world_shapes.dart';
import '../../logic/map_game_state.dart';

class WorldMapPainter extends CustomPainter {
  final Map<String, Owner> ownership;
  final Set<String> reachable;
  final String? highlighted;
  final bool dimUnreachable;

  static const _playerColor = Color(0xFF4ADE80);
  static const _aiColor = Color(0xFFF87171);

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

    // Ocean panel — teal→navy gradient, only within the map rect so the
    // surrounding area shows the screen's themed background.
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E6E8C), Color(0xFF09405A)],
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
        opacity = 0.92;
      } else if (isReachable) {
        opacity = 0.85;
      } else if (dimUnreachable) {
        opacity = 0.42;
      } else {
        opacity = 0.72;
      }

      final path = _shapePath(shape.points, rect);

      canvas.drawPath(
        path,
        Paint()
          ..color = fill.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );

      // Per-polygon border. Reachable continents get a bright gold edge so the
      // player can see where they may attack; others stay faint coastline lines.
      final borderColor = (isHighlighted || isReachable)
          ? const Color(0xFFFFD54F)
          : Colors.white.withAlpha(65);
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = (isHighlighted || isReachable) ? 1.4 : 0.5
          ..strokeJoin = StrokeJoin.round,
      );
    }

    canvas.restore(); // end clip

    // Panel frame.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withAlpha(40)
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
        Colors.white.withValues(alpha: visible ? 1.0 : 0.7),
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
          fontWeight: FontWeight.w800,
          height: 1.05,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2),
            Shadow(color: Colors.black54, blurRadius: 5),
          ],
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
