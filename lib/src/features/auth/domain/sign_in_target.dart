import 'package:meta/meta.dart';
import 'package:voxlivre/src/features/auth/domain/email_address.dart';
import 'package:voxlivre/src/features/auth/domain/phone_number.dart';

/// Où envoyer le code : un numéro (SMS) ou une adresse (e-mail).
@immutable
sealed class SignInTarget {
  const SignInTarget();

  /// Destination masquée, à afficher.
  String get masked;
}

/// Code par SMS.
final class PhoneTarget extends SignInTarget {
  const PhoneTarget(this.phone);

  final PhoneNumber phone;

  @override
  String get masked => phone.masked;

  @override
  bool operator ==(Object other) =>
      other is PhoneTarget && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;
}

/// Code par e-mail.
final class EmailTarget extends SignInTarget {
  const EmailTarget(this.email);

  final EmailAddress email;

  @override
  String get masked => email.masked;

  @override
  bool operator ==(Object other) =>
      other is EmailTarget && other.email == email;

  @override
  int get hashCode => email.hashCode;
}
