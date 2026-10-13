import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/shared/logging/app_logging.dart';

void main() {
  tearDown(() => Logger.root.level = Level.INFO);

  test('en release, aucun journal', () {
    configureLogging(enabled: false);

    expect(Logger.root.level, Level.OFF);
    expect(Logger('http').isLoggable(Level.SEVERE), isFalse);
  });

  test('en debug, chaque ligne passe par debugPrint', () {
    final printed = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    addTearDown(() => debugPrint = original);

    configureLogging(enabled: true);
    Logger('http').info('GET /health → ok');

    expect(Logger.root.level, Level.ALL);
    expect(printed, contains('[http] INFO GET /health → ok'));
  });

  test("l'erreur suit le message", () {
    final record = LogRecord(Level.WARNING, 'échec', 'http', 'TIMEOUT');

    expect(formatRecord(record), '[http] WARNING échec — TIMEOUT');
  });
}
