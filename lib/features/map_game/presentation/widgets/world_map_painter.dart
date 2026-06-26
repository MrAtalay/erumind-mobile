import 'package:flutter/material.dart';

import '../../data/continent_defs.dart';
import '../../logic/map_game_state.dart';

class WorldMapPainter extends CustomPainter {
  final Map<String, Owner> ownership;
  final Set<String> reachable;
  final String? highlighted; // continent being hovered/selected
  final bool dimUnreachable;

  static const _playerColor = Color(0xFF4ADE80);
  static const _aiColor = Color(0xFFFF6B6B);

  const WorldMapPainter({
    required this.ownership,
    required this.reachable,
    this.highlighted,
    this.dimUnreachable = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ocean background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A3A5C),
    );

    for (final c in kContinents) {
      final owner = ownership[c.id] ?? Owner.neutral;
      final isHighlighted = c.id == highlighted;
      final isReachable = reachable.contains(c.id);
      final isOwned = owner != Owner.neutral;

      final path = _makePath(c.polygon, size);

      // Colour
      Color fill = switch (owner) {
        Owner.player  => _playerColor,
        Owner.ai      => _aiColor,
        Owner.neutral => c.color,
      };

      double opacity;
      if (isHighlighted) {
        opacity = 1.0;
      } else if (isOwned) {
        opacity = 0.85;
      } else if (isReachable) {
        opacity = 0.80;
      } else if (dimUnreachable) {
        opacity = 0.30;
      } else {
        opacity = 0.55;
      }

      canvas.drawPath(path, Paint()
        ..color = fill.withValues(alpha: opacity)
        ..style = PaintingStyle.fill);

      // Border
      final strokeColor = isHighlighted
          ? Colors.white
          : isReachable
              ? Colors.white.withAlpha(180)
              : Colors.white.withAlpha(60);
      final strokeWidth = isHighlighted ? 2.5 : (isReachable ? 1.5 : 0.8);

      canvas.drawPath(path, Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth);

      // Label
      final labelPx = Offset(
        c.labelOffset.dx * size.width,
        c.labelOffset.dy * size.height,
      );
      final labelColor = Colors.white.withValues(
        alpha: isHighlighted || isOwned || isReachable ? 1.0 : 0.55,
      );
      _drawLabel(canvas, c.name, labelPx, labelColor, size.width * 0.14,
          fontSize: c.id == 'antarctica' || c.id == 'europe' ? 8.5 : 10.0);
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double maxWidth, {
    double fontSize = 10,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  static Path _makePath(List<Offset> polygon, Size size) {
    final path = Path();
    if (polygon.isEmpty) return path;
    path.moveTo(polygon.first.dx * size.width, polygon.first.dy * size.height);
    for (final p in polygon.skip(1)) {
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    path.close();
    return path;
  }

  /// Returns the continent id at [position] within [size], or null.
  static String? continentAt(Offset position, Size size) {
    for (final c in kContinents.reversed) {
      if (_makePath(c.polygon, size).contains(position)) return c.id;
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
