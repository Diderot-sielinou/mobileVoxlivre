// Génère l'icône de l'app à partir du logo dessiné en code (VoxLogoPainter).
// Hors de `test/` : la CI ne le lance pas. À relancer si le logo change :
//   flutter test tool/icons/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_logo.dart';

const _res = 'android/app/src/main/res';

/// Densités Android : facteur par rapport au mdpi.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Fond « Nuit d'encre » éclairé d'un halo Aube, puis le logo à [logoScale].
Future<List<int>> _render(
  int px, {
  required double logoScale,
  required bool background,
  double radius = 0,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = px.toDouble();
  final rect = Rect.fromLTWH(0, 0, size, size);
  if (background) {
    canvas
      ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
      ..drawRect(rect, Paint()..color = VoxColors.dark.background)
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              VoxGradients.aube.colors[1].withValues(alpha: 0.55),
              VoxColors.dark.background.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
  }
  final logo = size * logoScale;
  canvas.translate((size - logo) / 2, (size - logo) / 2);
  const VoxLogoPainter().paint(canvas, Size.square(logo));
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  test('icônes Android', () async {
    for (final MapEntry(key: name, value: k) in _densities.entries) {
      final dir = Directory('$_res/mipmap-$name')..createSync(recursive: true);
      // Icône classique (Android < 8) : carré arrondi complet.
      final legacy = (48 * k).round();
      File('${dir.path}/ic_launcher.png').writeAsBytesSync(
        await _render(
          legacy,
          logoScale: 0.78,
          background: true,
          radius: legacy * 0.22,
        ),
      );
      // Avant-plan adaptatif (Android 8+) : 108 dp, zone sûre de 66 dp.
      File('${dir.path}/ic_launcher_foreground.png').writeAsBytesSync(
        await _render((108 * k).round(), logoScale: 0.56, background: false),
      );
    }
    File('build/logo_preview.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(
        await _render(512, logoScale: 0.78, background: true, radius: 112),
      );
  });
}
