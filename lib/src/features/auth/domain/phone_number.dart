import 'package:meta/meta.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_failures.dart';

/// Numéro mobile camerounais au format E.164 (`+2376XXXXXXXX`).
@immutable
final class PhoneNumber {
  const PhoneNumber._(this.e164);

  /// Lit ce que tape l'utilisateur : `6 99 00 00 00`, `699000000`,
  /// `+237 699…`, `00237699…`. Espaces, points, tirets et parenthèses sont
  /// ignorés. Seuls les mobiles (`6` + 8 chiffres) sont acceptés.
  static Result<PhoneNumber, InvalidPhoneNumber> parse(String input) {
    var digits = input.replaceAll(RegExp(r'[\s().\-]'), '');
    if (digits.startsWith('+237')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('00237')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('237') && digits.length == 12) {
      digits = digits.substring(3);
    }
    if (!_localMobile.hasMatch(digits)) {
      return const Result.err(InvalidPhoneNumber());
    }
    return Result.ok(PhoneNumber._('+237$digits'));
  }

  static final _localMobile = RegExp(r'^6\d{8}$');

  /// Forme envoyée au backend : `+237699000419`.
  final String e164;

  /// Forme masquée pour l'écran : `+237 6•• •• •4 19`.
  String get masked {
    final local = e164.substring(4);
    return '+237 ${local[0]}•• •• •${local[6]} ${local.substring(7)}';
  }

  @override
  bool operator ==(Object other) => other is PhoneNumber && other.e164 == e164;

  @override
  int get hashCode => e164.hashCode;

  // Jamais le numéro en clair dans un journal.
  @override
  String toString() => 'PhoneNumber($masked)';
}
