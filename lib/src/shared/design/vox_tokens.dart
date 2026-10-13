/// Espacements, rayons et tailles du design system (grille de 4 dp).
abstract final class VoxSpacing {
  /// 4 dp.
  static const xs = 4.0;

  /// 8 dp.
  static const sm = 8.0;

  /// 16 dp.
  static const md = 16.0;

  /// 24 dp.
  static const lg = 24.0;

  /// 32 dp.
  static const xl = 32.0;

  /// Marge latérale des écrans.
  static const screenMargin = 20.0;
}

/// Rayons d'arrondi.
abstract final class VoxRadius {
  /// Champs, puces.
  static const chip = 12.0;

  /// Cartes.
  static const card = 20.0;

  /// Feuilles du bas.
  static const sheet = 28.0;
}

/// Tailles d'accessibilité.
abstract final class VoxSizes {
  /// Zone tactile minimale (Android).
  static const minTouchTarget = 48.0;

  /// Bouton Lecture/Pause du lecteur.
  static const playButton = 76.0;

  /// Taille de texte minimale d'une information.
  static const minTextSize = 14.0;

  /// Hauteur du bouton d'action principal.
  static const primaryButtonHeight = 52.0;

  /// Côté maximal d'une case du code de connexion.
  static const codeBox = 52.0;
}

/// Durées d'animation : la sortie est plus rapide que l'entrée.
abstract final class VoxMotion {
  /// Retour visuel d'un appui.
  static const tap = Duration(milliseconds: 120);

  /// Glissement du surlignage d'un mot au suivant.
  static const wordHighlight = Duration(milliseconds: 150);

  /// Ouverture d'une feuille.
  static const sheetIn = Duration(milliseconds: 300);

  /// Fermeture d'une feuille.
  static const sheetOut = Duration(milliseconds: 200);

  /// Rebond d'une case du code qui se remplit.
  static const codeFill = Duration(milliseconds: 150);

  /// Secousse d'un code refusé.
  static const codeShake = Duration(milliseconds: 300);

  /// Changement de page (onboarding), points de page.
  static const page = Duration(milliseconds: 300);

  /// Bascule entre deux contenus (champ téléphone / e-mail, bandeau).
  static const swap = Duration(milliseconds: 200);
}
