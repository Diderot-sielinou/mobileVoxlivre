import 'package:flutter/material.dart';

/// Familles de polices embarquées dans `assets/fonts/` (hors ligne : aucune
/// police téléchargée à l'exécution).
abstract final class VoxFonts {
  /// Interface et titres.
  static const ui = 'PlusJakartaSans';

  /// Texte de lecture : conçue pour les malvoyants, adaptée à la dyslexie.
  static const reading = 'AtkinsonHyperlegible';
}

/// Échelle typographique du design system (§1.3).
abstract final class VoxTypography {
  /// Échelle de l'interface, colorée par [text] et [textSecondary].
  static TextTheme textTheme({
    required Color text,
    required Color textSecondary,
  }) {
    TextStyle style(
      double size,
      double lineHeight,
      FontWeight weight, {
      Color? color,
    }) => TextStyle(
      fontFamily: VoxFonts.ui,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color ?? text,
    );

    return TextTheme(
      // H1 28/34, H2 22/28, H3 18/24.
      headlineLarge: style(28, 34, FontWeight.w700),
      headlineMedium: style(22, 28, FontWeight.w700),
      headlineSmall: style(18, 24, FontWeight.w600),
      titleLarge: style(20, 26, FontWeight.w600),
      titleMedium: style(16, 22, FontWeight.w600),
      titleSmall: style(14, 20, FontWeight.w600),
      bodyLarge: style(16, 22.4, FontWeight.w400),
      bodyMedium: style(14, 19.6, FontWeight.w400),
      // Jamais sous 14 : une information n'est pas écrite plus petit.
      bodySmall: style(14, 19.6, FontWeight.w400, color: textSecondary),
      labelLarge: style(16, 20, FontWeight.w600),
      labelMedium: style(14, 18, FontWeight.w600),
      labelSmall: style(14, 18, FontWeight.w500, color: textSecondary),
    );
  }

  /// Texte du livre dans le lecteur : 18, interligne 1,7, lettres espacées.
  static TextStyle reading(Color color) => TextStyle(
    fontFamily: VoxFonts.reading,
    fontSize: 18,
    height: 1.7,
    letterSpacing: 0.2,
    color: color,
  );

  /// Chiffres alignés (minuteur, quota) : ils ne « sautent » pas en changeant.
  static const tabularFigures = [FontFeature.tabularFigures()];
}
