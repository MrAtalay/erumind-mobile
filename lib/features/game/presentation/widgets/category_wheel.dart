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
  });

  final List<Category> categories;
  final void Function(Category category) onSelected;
  final String spinLabel;

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
        FilledButton(
          onPressed: _controller.isAnimating ? null : _spin,
          child: Text(widget.spinLabel),
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

    for (var i = 0; i < categories.length; i++) {
      // Sector i starts at the top (−π/2) and sweeps clockwise.
      final start = -math.pi / 2 + i * sweep;
      fill.color = Color(categories[i].colorValue);
      canvas.drawArc(rect, start, sweep, true, fill);

      _paintLabel(canvas, categories[i].name, start + sweep / 2, radius);
    }
    canvas.restore();

    // Fixed pointer at the top (drawn after restore so it doesn't rotate).
    final pointer = Path()
      ..moveTo(center.dx - 14, 2)
      ..lineTo(center.dx + 14, 2)
      ..lineTo(center.dx, 28)
      ..close();
    canvas.drawPath(pointer, Paint()..color = Colors.black87);

    // Centre hub.
    canvas.drawCircle(center, radius * 0.12, Paint()..color = Colors.white);
  }

  void _paintLabel(Canvas canvas, String text, double angle, double radius) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.rotate(angle);
    // Place the label out along the radius, vertically centred on the spoke.
    canvas.translate(radius * 0.42, -tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.rotation != rotation || old.categories != categories;
}
