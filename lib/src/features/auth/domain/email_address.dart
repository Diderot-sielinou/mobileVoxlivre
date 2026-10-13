import 'package:meta/meta.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_failures.dart';

/// Adresse e-mail, en minuscules et sans espaces autour.
@immutable
final class EmailAddress {
  const EmailAddress._(this.value);

  /// Vérification de forme seulement (`nom@domaine.tld`) : le code envoyé
  /// prouve que l'adresse existe.
  static Result<EmailAddress, InvalidEmailAddress> parse(String input) {
    final value = input.trim().toLowerCase();
    if (!_shape.hasMatch(value)) {
      return const Result.err(InvalidEmailAddress());
    }
    return Result.ok(EmailAddress._(value));
  }

  static final _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Adresse telle qu'envoyée au backend.
  final String value;

  /// Forme masquée pour l'écran : `a•••@gmail.com`.
  String get masked {
    final at = value.indexOf('@');
    return '${value[0]}•••${value.substring(at)}';
  }

  @override
  bool operator ==(Object other) =>
      other is EmailAddress && other.value == value;

  @override
  int get hashCode => value.hashCode;

  // Jamais l'adresse en clair dans un journal.
  @override
  String toString() => 'EmailAddress($masked)';
}
