import 'package:flutter/material.dart';

/// Couleurs sémantiques du design system « Encre & Aurore »
/// (`doc-projet/design_market_stich_voxlivre/DESIGN.md`). Les widgets lisent
/// ces jetons par `context.vox`, jamais une couleur en dur.
@immutable
class VoxColors extends ThemeExtension<VoxColors> {
  /// Jeu de couleurs complet.
  const VoxColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.text,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.wordHighlight,
    required this.onWordHighlight,
    required this.sentenceHalo,
  });

  /// Thème sombre, par défaut (« Nuit d'encre »).
  static const dark = VoxColors(
    background: Color(0xFF0B0B1A),
    surface: Color(0xFF16162B),
    elevated: Color(0xFF1F1F3A),
    border: Color(0xFF2E2E4D),
    // #6366F1 du design system assombri d’un cran : blanc dessus = 4,54:1 (AA).
    primary: Color(0xFF6165F0),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFF59E0B),
    onAccent: Color(0xFF1A1205),
    text: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFA5A3C2),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    wordHighlight: Color(0xFFF59E0B),
    onWordHighlight: Color(0xFF1A1205),
    sentenceHalo: Color(0x24F59E0B), // ambre à 14 %
  );

  /// Thème clair « Papier » (RF-26) : fond crème, moins d'éblouissement.
  static const paper = VoxColors(
    background: Color(0xFFFBF7F0),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFF3EDE2),
    border: Color(0xFFE4DCCD),
    primary: Color(0xFF4338CA),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    text: Color(0xFF1E1B2E),
    textSecondary: Color(0xFF5B5670),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    error: Color(0xFFDC2626),
    wordHighlight: Color(0xFFFDE68A),
    onWordHighlight: Color(0xFF1E1B2E),
    sentenceHalo: Color(0x2EF59E0B), // ambre à 18 %
  );

  /// Fond de l'application.
  final Color background;

  /// Cartes.
  final Color surface;

  /// Surfaces surélevées (feuilles, conteneurs secondaires).
  final Color elevated;

  /// Contours.
  final Color border;

  /// Indigo : actions principales.
  final Color primary;

  /// Texte sur [primary].
  final Color onPrimary;

  /// Ambre : appels à l'action, progression.
  final Color accent;

  /// Texte sur [accent].
  final Color onAccent;

  /// Texte principal.
  final Color text;

  /// Texte secondaire.
  final Color textSecondary;

  /// Succès.
  final Color success;

  /// Alerte (confiance OCR faible, unités insuffisantes).
  final Color warning;

  /// Erreur.
  final Color error;

  /// Fond du mot en cours de lecture.
  final Color wordHighlight;

  /// Texte du mot en cours de lecture.
  final Color onWordHighlight;

  /// Halo de la phrase en cours.
  final Color sentenceHalo;

  @override
  VoxColors copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? onAccent,
    Color? text,
    Color? textSecondary,
    Color? success,
    Color? warning,
    Color? error,
    Color? wordHighlight,
    Color? onWordHighlight,
    Color? sentenceHalo,
  }) => VoxColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    elevated: elevated ?? this.elevated,
    border: border ?? this.border,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    wordHighlight: wordHighlight ?? this.wordHighlight,
    onWordHighlight: onWordHighlight ?? this.onWordHighlight,
    sentenceHalo: sentenceHalo ?? this.sentenceHalo,
  );

  @override
  VoxColors lerp(VoxColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return VoxColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      elevated: mix(elevated, other.elevated),
      border: mix(border, other.border),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      error: mix(error, other.error),
      wordHighlight: mix(wordHighlight, other.wordHighlight),
      onWordHighlight: mix(onWordHighlight, other.onWordHighlight),
      sentenceHalo: mix(sentenceHalo, other.sentenceHalo),
    );
  }
}

/// Dégradés signature (un dégradé fort par écran au maximum).
abstract final class VoxGradients {
  /// Aube : splash, en-tête d'accueil, bouton « Convertir ».
  static const aube = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFF59E0B)],
  );

  /// Braise : appels à l'action, anneaux de progression, paiement.
  static const braise = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  /// Nuit : fond du lecteur plein écran.
  static const nuit = RadialGradient(
    center: Alignment(0, -0.6),
    colors: [Color(0xFF1E1B4B), Color(0xFF0B0B1A)],
  );
}

/// Accès court aux jetons : `context.vox.accent`.
extension VoxThemeContext on BuildContext {
  /// Les couleurs sémantiques du thème courant.
  VoxColors get vox => Theme.of(this).extension<VoxColors>()!;
}
