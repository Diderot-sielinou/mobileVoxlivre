import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_messages.dart';

void main() {
  test('chaque code connu a son message, les autres un message neutre', () {
    const codes = [
      'INVALID_PHONE_NUMBER',
      'INVALID_EMAIL',
      'INVALID_OTP',
      'OTP_EXPIRED',
      'TOO_MANY_ATTEMPTS',
      'OTP_RATE_LIMITED',
      'RATE_LIMITED',
      'NETWORK_UNAVAILABLE',
      'TIMEOUT',
    ];
    final fallback = authMessage('SERVER_ERROR');

    for (final code in codes) {
      expect(authMessage(code), isNot(fallback), reason: code);
    }
    expect(fallback, contains('Réessayez'));
    expect(authMessage('RATE_LIMITED'), authMessage('OTP_RATE_LIMITED'));
  });
}
