import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/habit_stats.dart';

/// Vertical bars of 0..1 completion ratios with sparse x labels.
class CompletionBarChart extends StatelessWidget {
  const CompletionBarChart({
    super.key,
    required this.buckets,
    this.height = 150,
  });
  final List<ChartBucket> buckets;
  final double height;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);
    final labelEvery = buckets.length <= 8 ? 1 : (buckets.length / 6).ceil();
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) {
          final slot = c.maxWidth / max(buckets.length, 1);
          final barW = min(slot * 0.62, 26.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < buckets.length; i++)
                SizedBox(
                  width: slot,
                  child: Tooltip(
                    message: buckets[i].isFuture
                        ? buckets[i].label
                        : '${buckets[i].label}: ${(buckets[i].value * 100).round()}%',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: buckets[i].value),
                              duration: Duration(milliseconds: 400 + i * 15),
                              curve: Curves.easeOutCubic,
                              builder: (_, v, _) => FractionallySizedBox(
                                heightFactor: max(v, 0.04),
                                child: Container(
                                  width: barW,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      min(barW / 2, 6),
                                    ),
                                    color: buckets[i].isFuture || v == 0
                                        ? colors.track
                                        : Color.lerp(
                                            primary.withValues(alpha: 0.35),
                                            primary,
                                            v,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 14,
                          child: i % labelEvery == 0
                              ? OverflowBox(
                                  maxWidth: 60,
                                  child: Text(
                                    buckets[i].label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: colors.muted,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Smooth line + area of 0..1 values; future buckets are omitted.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.buckets, this.height = 160});
  final List<ChartBucket> buckets;
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = buckets.where((b) => !b.isFuture).toList();
    final colors = AppColors.of(context);
    final labelEvery = points.length <= 8 ? 1 : (points.length / 5).ceil();
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => CustomPaint(
              painter: _TrendPainter(
                points.map((b) => b.value).toList(),
                Theme.of(context).colorScheme.primary,
                colors.border,
                Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                  color: colors.muted,
                ),
                t,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < points.length; i++)
                if (i % labelEvery == 0 || i == points.length - 1)
                  Text(
                    points[i].label,
                    style: TextStyle(fontSize: 10.5, color: colors.muted),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.color, this.grid, this.labelStyle, this.t);
  final List<double> values;
  final Color color;
  final Color grid;
  final TextStyle labelStyle;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    final w = size.width - left;
    final h = size.height - 8;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [0.0, 0.5, 1.0]) {
      final y = 4 + h * (1 - v);
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '${(v * 100).round()}%', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    if (values.isEmpty) return;

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          left + (values.length == 1 ? w / 2 : w * i / (values.length - 1)),
          4 + h * (1 - values[i] * t),
        ),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1], p1 = pts[i];
      final mx = (p0.dx + p1.dx) / 2;
      line.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    final area = Path.from(line)
      ..lineTo(pts.last.dx, 4 + h)
      ..lineTo(pts.first.dx, 4 + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    if (pts.length <= 14) {
      for (final p in pts) {
        canvas.drawCircle(p, 4, Paint()..color = color);
        canvas.drawCircle(p, 2, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.t != t || old.color != color || old.values != values;
}

/// Thin rounded progress bar.
class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: AppColors.of(context).track,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
