import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Animated circular progress ring with rounded caps.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 150,
    this.stroke = 12,
    this.color,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final track = c.withValues(alpha: 0.14);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(v, c, track, stroke),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    Paint stroked() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, stroked()..color = track);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * value,
      false,
      stroked()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: [color.withValues(alpha: 0.75), color],
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.track != track;
}

/// "73%" with an optional caption, sized for the middle of a ring.
class RingLabel extends StatelessWidget {
  const RingLabel({
    super.key,
    required this.value,
    this.caption,
    this.fontSize = 34,
  });
  final double value;
  final String? caption;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.of(context).muted),
          ),
      ],
    );
  }
}
