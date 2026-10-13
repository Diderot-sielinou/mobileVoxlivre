import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

final class _NotFound extends Failure {
  const _NotFound() : super('DOCUMENT_NOT_FOUND');
}

void main() {
  group('Result', () {
    const ok = Result<int, Failure>.ok(2);
    const err = Result<int, Failure>.err(_NotFound());

    test('tells a success from a failure', () {
      expect(ok.isOk, isTrue);
      expect(err.isErr, isTrue);
    });

    test('maps a success and leaves a failure untouched', () {
      expect(ok.map((v) => v * 10), const Result<int, Failure>.ok(20));
      expect(err.map((v) => v * 10).isErr, isTrue);
    });

    test('chains operations that may fail', () {
      Result<int, Failure> half(int v) =>
          v.isEven ? Result.ok(v ~/ 2) : const Result.err(_NotFound());

      expect(ok.flatMap(half), const Result<int, Failure>.ok(1));
      expect(const Result<int, Failure>.ok(3).flatMap(half).isErr, isTrue);
    });

    test('maps the error and falls back on a default value', () {
      final code = err.mapErr((f) => f.code);
      expect(code, const Result<int, String>.err('DOCUMENT_NOT_FOUND'));
      expect(err.valueOr(0), 0);
      expect(ok.valueOr(0), 2);
    });

    test('forces callers to handle both cases', () {
      final label = switch (err) {
        Ok(:final value) => 'valeur $value',
        Err(:final error) => 'échec ${error.code}',
      };
      expect(label, 'échec DOCUMENT_NOT_FOUND');
    });

    test('compares by value, usable in sets and logs', () {
      expect({ok, Result<int, Failure>.ok(int.parse('2'))}, hasLength(1));
      expect(ok.hashCode, const Result<int, Failure>.ok(2).hashCode);
      expect(err, const Result<int, Failure>.err(_NotFound()));
      expect(err.hashCode, isNot(ok.hashCode));
      expect(ok.toString(), 'Ok(2)');
      expect(err.toString(), 'Err(_NotFound(DOCUMENT_NOT_FOUND))');
    });
  });

  test('Failure carries no message nor details by default', () {
    const failure = _NotFound();
    expect(failure.message, isEmpty);
    expect(failure.details, isEmpty);
  });
}
