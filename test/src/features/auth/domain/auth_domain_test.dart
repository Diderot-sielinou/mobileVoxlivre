import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/email_address.dart';
import 'package:voxlivre/src/features/auth/domain/phone_number.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

void main() {
  group('PhoneNumber', () {
    test('accepte les écritures usuelles d’un mobile camerounais', () {
      for (final input in [
        '699000419',
        '6 99 00 04 19',
        '699-00-04-19',
        '+237 699 00 04 19',
        '237699000419',
        '00237699000419',
      ]) {
        expect(
          PhoneNumber.parse(input).map((p) => p.e164),
          const Result<String, Object>.ok('+237699000419'),
          reason: input,
        );
      }
    });

    test('refuse ce qui n’est pas un mobile (6 + 8 chiffres)', () {
      for (final input in [
        '',
        '233000419',
        '69900041',
        '6990004190',
        '+33612345678',
        'abc',
      ]) {
        expect(PhoneNumber.parse(input).isErr, isTrue, reason: input);
      }
      final failure = switch (PhoneNumber.parse('1')) {
        Err(:final error) => error.code,
        Ok() => null,
      };
      expect(failure, 'INVALID_PHONE_NUMBER');
    });

    test('se masque et ne s’écrit jamais en clair', () {
      final phone = _phone('699000419');

      expect(phone.masked, '+237 6•• •• •4 19');
      expect(phone.toString(), isNot(contains('699000419')));
      expect(phone, _phone('6 99 00 04 19'));
      expect(phone.hashCode, phone.e164.hashCode);
    });
  });

  group('EmailAddress', () {
    test('normalise et valide la forme', () {
      final email = EmailAddress.parse('  Lecteur@Mail.COM ');

      expect(
        email.map((e) => e.value),
        const Result<String, Object>.ok('lecteur@mail.com'),
      );
      for (final bad in ['', 'lecteur', 'lecteur@', '@mail.com', 'a b@c.d']) {
        expect(EmailAddress.parse(bad).isErr, isTrue, reason: bad);
      }
    });

    test('se masque et ne s’écrit jamais en clair', () {
      final email = _email('lecteur@mail.com');

      expect(email.masked, 'l•••@mail.com');
      expect(email.toString(), isNot(contains('lecteur')));
      expect(
        email,
        _email('LECTEUR@mail.com'),
      );
      expect(email.hashCode, email.value.hashCode);
    });
  });

  test('SignInTarget compare par valeur et rend la forme masquée', () {
    final phone = _phone('699000419');
    final email = _email('a@b.cd');

    expect(PhoneTarget(phone), PhoneTarget(phone));
    expect(PhoneTarget(phone).hashCode, phone.hashCode);
    expect(PhoneTarget(phone).masked, phone.masked);
    expect(EmailTarget(email), EmailTarget(email));
    expect(EmailTarget(email).hashCode, email.hashCode);
    expect(EmailTarget(email).masked, 'a•••@b.cd');
  });
}

PhoneNumber _phone(String input) => switch (PhoneNumber.parse(input)) {
  Ok(:final value) => value,
  Err() => throw StateError('numéro attendu valide : $input'),
};

EmailAddress _email(String input) => switch (EmailAddress.parse(input)) {
  Ok(:final value) => value,
  Err() => throw StateError('adresse attendue valide : $input'),
};
