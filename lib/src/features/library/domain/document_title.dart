import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

/// Titre refusé avant tout appel (mêmes règles que le backend).
final class InvalidDocumentTitle extends Failure {
  const InvalidDocumentTitle() : super('INVALID_DOCUMENT_TITLE');
}

/// Règles du titre d'un document, comme `DocumentTitle` du backend :
/// espaces normalisés, 1 à 200 caractères, sans caractère de contrôle.
abstract final class DocumentTitle {
  static const maxLength = 200;

  static final _spaces = RegExp(r'\s+');
  static final _control = RegExp(r'[\u0000-\u001F\u007F-\u009F]');

  static Result<String, InvalidDocumentTitle> parse(String input) {
    final value = input.trim().replaceAll(_spaces, ' ');
    if (value.isEmpty || value.length > maxLength || _control.hasMatch(value)) {
      return const Result.err(InvalidDocumentTitle());
    }
    return Result.ok(value);
  }
}
