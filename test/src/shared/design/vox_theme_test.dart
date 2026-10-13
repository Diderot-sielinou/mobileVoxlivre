import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_theme.dart';

/// Rapport de contraste WCAG 2 entre deux couleurs opaques.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final themes = {'sombre': VoxColors.dark, 'Papier': VoxColors.paper};

  for (final MapEntry(key: name, value: c) in themes.entries) {
    group('contrastes AA du thème $name', () {
      // Paires texte/fond réellement utilisées : chacune doit tenir 4,5:1.
      final pairs = {
        'texte / fond': (c.text, c.background),
        'texte / carte': (c.text, c.surface),
        'texte / surélevé': (c.text, c.elevated),
        'texte secondaire / fond': (c.textSecondary, c.background),
        'texte secondaire / carte': (c.textSecondary, c.surface),
        'texte secondaire / surélevé': (c.textSecondary, c.elevated),
        'sur primaire / primaire': (c.onPrimary, c.primary),
        'sur accent / accent': (c.onAccent, c.accent),
        'mot surligné': (c.onWordHighlight, c.wordHighlight),
        'erreur / fond': (c.error, c.background),
        'succès / fond': (c.success, c.background),
        'avertissement / fond': (c.warning, c.background),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }

  test('chaque ThemeData expose ses jetons par extension', () {
    expect(VoxTheme.dark.extension<VoxColors>(), VoxColors.dark);
    expect(VoxTheme.paper.extension<VoxColors>(), VoxColors.paper);
    expect(VoxTheme.dark.brightness, Brightness.dark);
    expect(VoxTheme.paper.brightness, Brightness.light);
  });

  testWidgets('context.vox lit les jetons du thème courant', (tester) async {
    late VoxColors read;
    await tester.pumpWidget(
      MaterialApp(
        theme: VoxTheme.paper,
        home: Builder(
          builder: (context) {
            read = context.vox;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, VoxColors.paper);
  });

  test('aucun texte de l’interface sous 14', () {
    final t = VoxTheme.dark.textTheme;
    final styles = [
      t.headlineLarge,
      t.headlineMedium,
      t.headlineSmall,
      t.titleLarge,
      t.titleMedium,
      t.titleSmall,
      t.bodyLarge,
      t.bodyMedium,
      t.bodySmall,
      t.labelLarge,
      t.labelMedium,
      t.labelSmall,
    ];
    for (final s in styles) {
      expect(s!.fontSize, greaterThanOrEqualTo(14));
    }
  });
}
