import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';

/// Logo Voxlivre : une onde sonore qui se pose sur un livre ouvert (design
/// system, splash). Dessiné en code : net à toute taille, aucune image à
/// embarquer, et animable ([progress] fait monter les barres de 0 à 1).
class VoxLogo extends StatelessWidget {
  const VoxLogo({this.size = 96, this.progress = 1, super.key});

  final double size;

  /// Hauteur des barres, de 0 (à plat) à 1 (dessin final).
  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Logo Voxlivre',
    child: CustomPaint(
      size: Size.square(size),
      painter: VoxLogoPainter(progress: progress),
    ),
  );
}

/// Peintre du [VoxLogo], réutilisé pour générer l'icône de l'app.
class VoxLogoPainter extends CustomPainter {
  const VoxLogoPainter({this.progress = 1});

  final double progress;

  // Teintes de l'« Aube » : violet aux bords, ambre vers le centre, barre
  // centrale claire (comme la maquette du splash).
  static final Color _violet = VoxGradients.aube.colors[1];
  static final Color _amber = VoxGradients.aube.colors[2];
  static final Color _ember = VoxGradients.braise.colors.last;
  static const Color _light = VoxGradients.onAube;

  /// Couleur de chaque barre, des bords vers le centre.
  static final List<Color> _barColors = [
    _violet,
    _amber,
    _ember,
    _light,
    _ember,
    _amber,
    _violet,
  ];

  /// Hauteurs relatives des 7 barres, symétriques.
  static const _bars = [0.16, 0.28, 0.40, 0.52, 0.40, 0.28, 0.16];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final dx = (size.width - s) / 2;
    final dy = (size.height - s) / 2;
    canvas
      ..save()
      ..translate(dx, dy);

    // Livre ouvert : deux pages incurvées qui se rejoignent au dos.
    final spine = Offset(s * 0.5, s * 0.80);
    final book = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.045
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [_violet, _amber, _violet],
      ).createShader(Rect.fromLTWH(0, 0, s, s));
    for (final side in [-1.0, 1.0]) {
      final page = Path()
        ..moveTo(spine.dx, spine.dy)
        ..quadraticBezierTo(
          s * (0.5 + side * 0.18),
          s * 0.68,
          s * (0.5 + side * 0.40),
          s * 0.74,
        );
      canvas.drawPath(page, book);
    }

    // Onde : 7 barres posées sur les pages.
    final barWidth = s * 0.05;
    final gap = s * 0.025;
    final total = _bars.length * barWidth + (_bars.length - 1) * gap;
    final baseline = s * 0.66;
    final eased = Curves.easeOutCubic.transform(progress.clamp(0, 1));
    for (var i = 0; i < _bars.length; i++) {
      final height = math.max(barWidth, s * _bars[i] * eased);
      final left = s * 0.5 - total / 2 + i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, baseline - height, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, Paint()..color = _barColors[i]);
    }

    // Point ambre au-dessus de la barre centrale : la voix qui « s'allume ».
    canvas
      ..drawCircle(
        Offset(s * 0.5, baseline - s * _bars[3] * eased - s * 0.07),
        s * 0.025 * eased,
        Paint()..color = _amber,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(VoxLogoPainter old) => old.progress != progress;
}
