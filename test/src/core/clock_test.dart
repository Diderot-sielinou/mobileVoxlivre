import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/clock.dart';

void main() {
  test('SystemClock donne l’heure courante en UTC', () {
    final before = DateTime.now().toUtc();
    final now = const SystemClock().now();

    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
  });
}
