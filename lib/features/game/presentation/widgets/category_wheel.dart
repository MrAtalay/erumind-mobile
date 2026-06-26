import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/category.dart';

/// A spinning wheel of [categories]. Tapping "spin" accelerates and decelerates
/// to a random sector, then reports the landed [Category] via [onSelected].
///
/// Reusable across the game flow (the Momentum loop spins it before every
/// question). Self-contained: owns its animation and the spin button.
class CategoryWheel extends StatefulWidget {
  const CategoryWheel({
    super.key,
    required this.categories,
    required this.onSelected,
    required this.spinLabel,
    this.onSpinStart,
  });

  final List<Category> categories;
  final void Function(Category category) onSelected;
  final String spinLabel;

  /// Called right as a spin begins (before the wheel animates).
  final VoidCallback? onSpinStart;

  @override
  State<CategoryWheel> createState() => _CategoryWheelState();
}

class _CategoryWheelState extends State<CategoryWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late Animation<double> _rotation =
      const AlwaysStoppedAnimation<double>(0);

  final _random = math.Random();
  double _current = 0; // current resting rotation, radians

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_controller.isAnimating) return;
    widget.onSpinStart?.call();

    final count = widget.categories.length;
    final sweep = 2 * math.pi / count;
    final index = _random.nextInt(count);

    // Rotation that brings sector [index]'s centre under the top pointer.
    final targetBase = -(index * sweep + sweep / 2);
    final normalized = _current % (2 * math.pi);
    final delta = (targetBase - normalized) % (2 * math.pi);
    final target = _current + 2 * math.pi * 4 + delta; // 4 full turns + delta

    _rotation = Tween<double>(begin: _current, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller
      ..reset()
      ..forward().whenComplete(() {
        _current = target;
        widget.onSelected(widget.categories[index]);
      });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: AnimatedBuilder(
            animation: _rotation,
            builder: (context, _) {
              return CustomPaint(
                painter: _WheelPainter(
                  categories: widget.categories,
                  rotation: _rotation.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _controller.isAnimating ? null : _spin,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            decoration: BoxDecoration(
              color: _controller.isAnimating
                  ? const Color(0x44CC1020)
                  : const Color(0xFFCC1020),
              borderRadius: BorderRadius.circular(30),
              boxShadow: _controller.isAnimating
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFCC1020).withAlpha(100),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Text(
              widget.spinLabel,
              style: TextStyle(
                color: _controller.isAnimating
                    ? Colors.white38
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.categories, required this.rotation});

  final List<Category> categories;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final sweep = 2 * math.pi / categories.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final fill = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);

    final divider = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withAlpha(60)
      ..strokeWidth = 1.5;

    for (var i = 0; i < categories.length; i++) {
      // Sector i starts at the top (−π/2) and sweeps clockwise.
      final start = -math.pi / 2 + i * sweep;
      fill.color = Color(categories[i].colorValue);
      canvas.drawArc(rect, start, sweep, true, fill);
      canvas.drawArc(rect, start, sweep, true, divider);

      _paintLabel(canvas, categories[i].name, start + sweep / 2, radius);
    }
    canvas.restore();

    // Outer ring (frames the wheel against the dark background).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withAlpha(50)
        ..strokeWidth = 3,
    );

    // Fixed pointer at the top (drawn after restore so it doesn't rotate).
    final pointer = Path()
      ..moveTo(center.dx - 12, 0)
      ..lineTo(center.dx + 12, 0)
      ..lineTo(center.dx, 22)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.white);
    canvas.drawPath(
      pointer,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withAlpha(80)
        ..strokeWidth = 1,
    );

    // Centre hub.
    canvas.drawCircle(center, radius * 0.12, Paint()..color = Colors.white);
  }

  void _paintLabel(Canvas canvas, String text, double angle, double radius) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    // The radial band available for the label (outside the hub, inside the rim).
    const innerFactor = 0.20;
    const outerFactor = 0.92;
    final available = radius * (outerFactor - innerFactor);
    final mid = radius * (innerFactor + outerFactor) / 2;
    // Shrink long labels (e.g. "Entertainment") so they never spill past the rim.
    final scale = tp.width > available ? available / tp.width : 1.0;

    canvas.save();
    canvas.rotate(angle);
    canvas.translate(mid, 0);
    // Keep text upright: flip the spokes that currently point to the left half.
    if (math.cos(rotation + angle) < 0) {
      canvas.rotate(math.pi);
    }
    canvas.scale(scale);
    canvas.translate(-tp.width / 2, -tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation || old.categories != categories;
}
