import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Draws one broad, rounded leaf from [base] to [tip], shaded [from] → [to].
void drawLeaf(
  Canvas canvas,
  Offset base,
  Offset tip, {
  required Color from,
  required Color to,
  double width = 0.42,
  bool vein = true,
}) {
  final d = tip - base;
  final len = d.distance;
  if (len < 1) return;
  final n = Offset(-d.dy, d.dx) / len * (len * width);
  final path = Path()
    ..moveTo(base.dx, base.dy)
    ..cubicTo(
      base.dx + d.dx * 0.15 + n.dx * 0.9,
      base.dy + d.dy * 0.15 + n.dy * 0.9,
      base.dx + d.dx * 0.72 + n.dx * 0.85,
      base.dy + d.dy * 0.72 + n.dy * 0.85,
      tip.dx,
      tip.dy,
    )
    ..cubicTo(
      base.dx + d.dx * 0.72 - n.dx * 0.85,
      base.dy + d.dy * 0.72 - n.dy * 0.85,
      base.dx + d.dx * 0.15 - n.dx * 0.9,
      base.dy + d.dy * 0.15 - n.dy * 0.9,
      base.dx,
      base.dy,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()..shader = ui.Gradient.linear(base, tip, [from, to]),
  );
  if (vein) {
    canvas.drawLine(
      base + d * 0.06,
      base + d * 0.86,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = max(1, len * 0.035)
        ..strokeCap = StrokeCap.round,
    );
  }
}

Color _deep(Color c) => Color.lerp(c, Colors.black, 0.28)!;
Color _bright(Color c) => Color.lerp(c, const Color(0xFFB8F0A8), 0.35)!;

/// A potted plant drawn in code; [growth] (0..1) controls how many leaves show,
/// so the plant visibly grows as the day's habits are completed.
class PlantIllustration extends StatelessWidget {
  const PlantIllustration({
    super.key,
    this.size = 120,
    this.growth = 1,
    this.color,
  });
  final double size;
  final double growth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: growth.clamp(0, 1)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (_, g, _) => CustomPaint(
        size: Size.square(size),
        painter: PlantPainter(c, g, dark),
      ),
    );
  }
}

class PlantPainter extends CustomPainter {
  PlantPainter(this.color, this.growth, this.dark);
  final Color color;
  final double growth;
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final deep = _deep(color);
    final bright = _bright(color);

    // Pot body with soft side shading.
    final potTop = h * 0.70;
    final pot = Path()
      ..moveTo(w * 0.31, potTop)
      ..lineTo(w * 0.69, potTop)
      ..lineTo(w * 0.635, h * 0.975)
      ..quadraticBezierTo(w * 0.5, h * 1.0, w * 0.365, h * 0.975)
      ..close();
    final potBase = dark ? const Color(0xFFDCE4DF) : Colors.white;
    canvas.drawShadow(pot, Colors.black26, 5, false);
    canvas.drawPath(
      pot,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.31, 0),
          Offset(w * 0.69, 0),
          [potBase, Color.lerp(potBase, const Color(0xFF9AA59F), 0.18)!],
        ),
    );
    // Rim.
    final rim = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.275, potTop - h * 0.045, w * 0.45, h * 0.075),
      Radius.circular(h * 0.025),
    );
    canvas.drawRRect(
      rim,
      Paint()..color = Color.lerp(potBase, const Color(0xFF9AA59F), 0.10)!,
    );
    // Soil.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, potTop - h * 0.035),
        width: w * 0.40,
        height: h * 0.04,
      ),
      Paint()..color = const Color(0xFF3B2F27),
    );

    // Stem.
    final soil = Offset(w * 0.5, potTop - h * 0.04);
    final stemTop = Offset(w * 0.5, soil.dy - h * (0.18 + 0.36 * growth));
    final stemPaint = Paint()
      ..color = deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(soil.dx, soil.dy)
        ..quadraticBezierTo(
          w * 0.47,
          (soil.dy + stemTop.dy) / 2,
          stemTop.dx,
          stemTop.dy,
        ),
      stemPaint,
    );

    // Leaves: (position along stem, angle, length, appears at growth).
    const leaves = [
      (0.10, -2.55, 0.34, 0.0),
      (0.10, -0.60, 0.34, 0.0),
      (0.45, -2.75, 0.30, 0.3),
      (0.45, -0.40, 0.31, 0.45),
      (0.78, -2.30, 0.27, 0.65),
      (0.78, -0.85, 0.27, 0.8),
      (1.00, -pi / 2, 0.24, 0.92),
    ];
    for (var i = 0; i < leaves.length; i++) {
      final (t, angle, len, appear) = leaves[i];
      final visible = ((growth - appear) / 0.15).clamp(0.0, 1.0);
      if (visible <= 0 && i > 1) continue;
      final scale = i <= 1 ? max(0.6, visible) : visible;
      final base = Offset.lerp(soil, stemTop, t)!;
      final l = w * len * scale;
      // Short petiole, then the leaf.
      final petiole = base + Offset(cos(angle), sin(angle)) * l * 0.12;
      canvas.drawLine(base, petiole, stemPaint..strokeWidth = w * 0.02);
      drawLeaf(
        canvas,
        petiole,
        petiole + Offset(cos(angle), sin(angle)) * l,
        from: deep,
        to: i.isEven ? bright : color,
        width: 0.44,
      );
    }
  }

  @override
  bool shouldRepaint(PlantPainter old) =>
      old.growth != growth || old.color != color || old.dark != dark;
}

/// Two-leaf sprout used as the app logo.
class SproutLogo extends StatelessWidget {
  const SproutLogo({super.key, this.size = 30, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SproutPainter(color ?? Theme.of(context).colorScheme.primary),
  );
}

class _SproutPainter extends CustomPainter {
  _SproutPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final deep = _deep(color);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.96)
        ..quadraticBezierTo(w * 0.46, h * 0.72, w * 0.5, h * 0.48),
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075
        ..strokeCap = StrokeCap.round,
    );
    drawLeaf(
      canvas,
      Offset(w * 0.48, h * 0.56),
      Offset(w * 0.04, h * 0.24),
      from: deep,
      to: _bright(color),
      width: 0.46,
    );
    drawLeaf(
      canvas,
      Offset(w * 0.52, h * 0.50),
      Offset(w * 0.97, h * 0.10),
      from: deep,
      to: color,
      width: 0.46,
    );
  }

  @override
  bool shouldRepaint(_SproutPainter old) => old.color != color;
}

/// Sprout growing from a mound inside a soft green circle (About page logo).
class SproutBadge extends StatelessWidget {
  const SproutBadge({super.key, this.size = 104});
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: 0.10),
              primary.withValues(alpha: 0.28),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _MoundPainter(primary),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              size * 0.2,
              size * 0.1,
              size * 0.2,
              size * 0.24,
            ),
            child: SproutLogo(size: size * 0.6),
          ),
        ),
      ),
    );
  }
}

class _MoundPainter extends CustomPainter {
  _MoundPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.82)
        ..quadraticBezierTo(w * 0.5, h * 0.62, w, h * 0.82)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.9)
        ..quadraticBezierTo(w * 0.55, h * 0.74, w, h * 0.92)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = _deep(color).withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_MoundPainter old) => old.color != color;
}

/// Soft translucent leaves and hills, used behind hero sections.
///
/// The bottom edge (and optionally the top) fades out so it blends into the
/// page background.
class LeafBackdrop extends StatelessWidget {
  const LeafBackdrop({super.key, this.fadeTop = false});
  final bool fadeTop;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.infinite,
      painter: _LeafBackdropPainter(
        Theme.of(context).colorScheme.primary,
        fadeTop,
      ),
    ),
  );
}

class _LeafBackdropPainter extends CustomPainter {
  _LeafBackdropPainter(this.color, this.fadeTop);
  final Color color;
  final bool fadeTop;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.saveLayer(Offset.zero & s, Paint());
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h), [
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0.03),
        ]),
    );
    final a = color.withValues(alpha: 0.10);
    final b = color.withValues(alpha: 0.18);
    void leaf(double bx, double by, double tx, double ty, double width) =>
        drawLeaf(
          canvas,
          Offset(w * bx, h * by),
          Offset(w * tx, h * ty),
          from: b,
          to: a,
          width: width,
          vein: false,
        );
    leaf(0.02, 1.05, 0.16, 0.45, 0.5);
    leaf(0.12, 1.05, 0.42, 0.62, 0.45);
    leaf(0.50, 1.05, 0.62, 0.55, 0.42);
    leaf(1.02, 1.0, 0.80, 0.30, 0.45);
    leaf(0.96, 1.05, 0.62, 0.70, 0.40);
    // Hills.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.86)
        ..quadraticBezierTo(w * 0.35, h * 0.66, w * 0.7, h * 0.84)
        ..quadraticBezierTo(w * 0.88, h * 0.92, w, h * 0.80)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color.withValues(alpha: 0.08),
    );
    // Fade edges into the page background.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, h),
          fadeTop
              ? const [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ]
              : const [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
          fadeTop ? const [0, 0.18, 0.7, 1] : const [0, 0.75, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafBackdropPainter old) =>
      old.color != color || old.fadeTop != fadeTop;
}

/// A cluster of large leaves growing from the bottom-right corner.
class CornerLeaves extends StatelessWidget {
  const CornerLeaves({super.key, this.size = 150});
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      size: Size.square(size),
      painter: _CornerLeavesPainter(Theme.of(context).colorScheme.primary),
    ),
  );
}

class _CornerLeavesPainter extends CustomPainter {
  _CornerLeavesPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final base = Offset(w * 0.72, h * 1.02);
    final deep = _deep(color);
    final stem = Paint()
      ..color = deep
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    for (final (tx, ty, width, light) in [
      (0.08, 0.42, 0.40, true),
      (0.36, 0.08, 0.40, false),
      (0.80, 0.02, 0.38, true),
      (1.05, 0.38, 0.40, false),
    ]) {
      final tip = Offset(w * tx, h * ty);
      final mid = Offset.lerp(base, tip, 0.25)!;
      canvas.drawLine(base, mid, stem);
      drawLeaf(
        canvas,
        mid,
        tip,
        from: deep.withValues(alpha: 0.85),
        to: (light ? _bright(color) : color).withValues(alpha: 0.85),
        width: width,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerLeavesPainter old) => old.color != color;
}

/// Soft rolling hills used as a decorative backdrop.
class HillsBackdrop extends StatelessWidget {
  const HillsBackdrop({super.key, this.height = 140});
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _HillsPainter(c),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final back = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.3, h * 0.15, w * 0.62, h * 0.5)
      ..quadraticBezierTo(w * 0.85, h * 0.75, w, h * 0.35)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = color.withValues(alpha: 0.07));
    final front = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.45, h * 0.45, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = color.withValues(alpha: 0.10));
  }

  @override
  bool shouldRepaint(_HillsPainter old) => old.color != color;
}

/// App logo: the two-leaf sprout in the accent color.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => SproutLogo(size: size);
}

/// Potted plant on a soft radial glow; used as a page hero.
class PlantHero extends StatelessWidget {
  const PlantHero({super.key, this.size = 170});
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primary.withValues(alpha: 0.20),
            primary.withValues(alpha: 0.06),
            primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.65, 1],
        ),
      ),
      alignment: Alignment.center,
      child: PlantIllustration(size: size * 0.8),
    );
  }
}
