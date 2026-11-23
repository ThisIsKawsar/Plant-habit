// Renders the app's plant illustration into launcher-icon PNGs.
//
// Run:  flutter test tool/generate_icon_test.dart
//       dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_habit/widgets/plant_art.dart';

const _size = 1024.0;
const _green = Color(0xFF2E9B3F);

Future<void> _write(String path, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void _background(Canvas c) {
  const rect = Rect.fromLTWH(0, 0, _size, _size);
  c.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEFFAF0), Color(0xFFC9EBCF)],
      ).createShader(rect),
  );
  // Soft hill behind the pot.
  c.drawPath(
    Path()
      ..moveTo(0, _size * 0.82)
      ..quadraticBezierTo(_size * 0.5, _size * 0.62, _size, _size * 0.82)
      ..lineTo(_size, _size)
      ..lineTo(0, _size)
      ..close(),
    Paint()..color = _green.withValues(alpha: 0.12),
  );
}

void _plant(Canvas c, double scale) {
  final plantSize = _size * scale;
  c.save();
  c.translate((_size - plantSize) / 2, (_size - plantSize) / 2);
  PlantPainter(_green, 1, false).paint(c, Size.square(plantSize));
  c.restore();
}

void main() {
  test('generate launcher icons', () async {
    await _write('assets/icon/icon.png', (c) {
      _background(c);
      _plant(c, 0.78);
    });
    // Android adaptive icon foreground: keep inside the 66% safe zone.
    await _write('assets/icon/icon_foreground.png', (c) => _plant(c, 0.58));
  });
}
