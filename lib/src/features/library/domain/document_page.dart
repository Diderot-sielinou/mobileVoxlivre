import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

/// Pourquoi une ligne a été retirée du texte lu (ADR-0022 et 0025 du
/// backend).
enum SetAsideReason {
  header,
  footer,
  pageNumber,
  footnote,
  caption,
  table,
  unknown;

  static SetAsideReason fromWire(String value) => switch (value) {
    'header' => header,
    'footer' => footer,
    'page_number' => pageNumber,
    'footnote' => footnote,
    'caption' => caption,
    'table' => table,
    _ => unknown,
  };
}

/// Ligne retirée du texte lu par le nettoyage automatique.
final class SetAsideLine {
  const SetAsideLine(this.text, this.reason);

  final String text;
  final SetAsideReason reason;
}

/// Texte d'une page du livre, pour la vérification (RF-06).
final class DocumentPage {
  const DocumentPage({
    required this.pageNumber,
    required this.text,
    this.setAside = const [],
    this.confidence,
  });

  final int pageNumber;

  /// Lignes séparées par des sauts de ligne.
  final String text;
  final List<SetAsideLine> setAside;

  /// Confiance de l'OCR (0 à 1) ; `null` pour un PDF texte.
  final double? confidence;

  /// Sous ce seuil, la page est à relire en priorité (ADR-0024 du backend).
  static const reviewThreshold = 0.8;

  bool get needsReview => (confidence ?? 1) < reviewThreshold;

  /// Lignes retirées qui ne sont pas (déjà) revenues dans le texte.
  List<SetAsideLine> get stillSetAside => [
    for (final line in setAside)
      if (!text.contains(line.text.trim())) line,
  ];

  /// [text] avec [line] remise à sa place probable : en tête pour un
  /// en-tête, à la fin sinon. L'utilisateur ajuste avant d'enregistrer.
  String withLine(SetAsideLine line) {
    final body = text.trim();
    if (body.isEmpty) return line.text;
    return line.reason == SetAsideReason.header
        ? '${line.text}\n$body'
        : '$body\n${line.text}';
  }
}

/// Texte de page refusé avant tout appel.
final class InvalidPageText extends Failure {
  const InvalidPageText() : super('INVALID_PAGE_TEXT');
}

/// Règles du texte d'une page, comme `PageText` du backend : 20 000
/// caractères au plus, sans caractère de contrôle (tabulation et saut de
/// ligne permis). Une page peut devenir vide.
abstract final class PageText {
  static const maxLength = 20000;

  static final _forbidden = RegExp(
    r'[\u0000-\u0008\u000B-\u001F\u007F-\u009F]',
  );

  static Result<String, InvalidPageText> parse(String input) {
    final value = input.replaceAll('\r\n', '\n').trim();
    if (value.length > maxLength || _forbidden.hasMatch(value)) {
      return const Result.err(InvalidPageText());
    }
    return Result.ok(value);
  }
}
