import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/shared/http/request_id.dart';

void main() {
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('un UUID v4 bien formé', () {
    for (var i = 0; i < 100; i++) {
      expect(newRequestId(), matches(uuidV4));
    }
  });

  test('deux identifiants diffèrent', () {
    expect(newRequestId(), isNot(newRequestId()));
  });

  test('le tirage vient de la source donnée', () {
    expect(newRequestId(Random(1)), newRequestId(Random(1)));
  });
}
