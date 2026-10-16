import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/clear_positions.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/application/open_book.dart';
import 'package:voxlivre/src/features/player/application/save_position.dart';
import 'package:voxlivre/src/features/player/domain/book_session.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/domain/timed_word.dart';
import 'package:voxlivre/src/features/player/domain/webvtt.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

import '../../../helpers/app_harness.dart';
import 'fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

TimedWord w(int index, String text, int startMs) => TimedWord(
  index: index,
  text: text,
  startMs: startMs,
  endMs: startMs + 1000,
);

void main() {
  group('WebVTT', () {
    test('un repère par mot, instants absolus, texte déséchappé', () {
      final words = parseWebVtt(
        'WEBVTT\n\n'
        '12\n00:00:01.250 --> 00:00:01.900\nR&amp;D\n\n'
        'abc\n00:00:02.000 --> 00:00:03.000\nignoré\n\n'
        '13\n01:02:03.004 --> 01:02:04.000\n&lt;mot&gt;\n',
        offsetMs: 10000,
      );

      expect(words.map((x) => (x.index, x.text, x.startMs, x.endMs)), [
        (12, 'R&D', 11250, 11900),
        (13, '<mot>', 10000 + 3723004, 10000 + 3724000),
      ]);
    });
  });

  group('BookText', () {
    final text = BookText(
      [
        w(3, 'Il', 3000),
        w(0, 'Le', 0),
        w(1, 'droit', 1000),
        w(2, 'civil.', 2000),
        w(4, 'règle.', 4000),
      ],
      [(page: 2, wordIndex: 3), (page: 1, wordIndex: 0)],
    );

    test('le mot prononcé à un instant (recherche dichotomique)', () {
      expect(text.words.first.text, 'Le', reason: 'trié par index');
      expect(text.positionAt(-1), -1);
      expect(text.positionAt(0), 0);
      expect(text.positionAt(1999), 1);
      expect(text.positionAt(99999), 4);
      expect(text.positionOfWord(3), 3);
      expect(text.positionOfWord(99), -1);
    });

    test('la phrase, les pages', () {
      expect(text.sentenceAround(1), (start: 0, end: 2));
      expect(text.sentenceAround(3), (start: 3, end: 4));
      expect(text.pageOf(2), 1);
      expect(text.pageOf(3), 2);
      expect(text.pages, [
        (page: 1, from: 0, to: 2),
        (page: 2, from: 3, to: 4),
      ]);
      expect(BookText(const [], const []).pages, isEmpty);
      expect(BookText(const [], const []).pageOf(-1), 1);
    });
  });

  test('position : la plus récente gagne', () {
    final old = ReadingPosition(
      wordIndex: 1,
      audioMs: 1,
      recordedAt: DateTime.utc(2026, 10, 2, 8),
    );
    final recent = ReadingPosition(
      wordIndex: 2,
      audioMs: 2,
      recordedAt: DateTime.utc(2026, 10, 3),
    );
    expect(ReadingPosition.latest(old, recent), recent);
    expect(ReadingPosition.latest(recent, old), recent);
    expect(ReadingPosition.latest(null, old), old);
    expect(ReadingPosition.latest(null, null), isNull);
  });

  test('manifeste : parties écoutables dans l’ordre, sans trou', () {
    expect(testManifest().playableParts.map((p) => p.index), [0, 1]);
    expect(
      testManifest(secondReady: false).playableParts.map((p) => p.index),
      [0],
    );
  });

  test('horloge et vitesse', () {
    expect(VoxFormat.clock(0), '0:00');
    expect(VoxFormat.clock(65000), '1:05');
    expect(VoxFormat.clock(3729000), '1:02:09');
    expect(VoxFormat.clock(-5), '0:00');
  });

  group('cas d’usage', () {
    late FakePlayerGateway gateway;
    late MemoryPositionStore store;
    late MemoryBookFiles files;

    setUp(() {
      gateway = FakePlayerGateway();
      store = MemoryPositionStore();
      files = MemoryBookFiles(gateway.disk);
    });

    OpenBook open() =>
        OpenBook(gateway, store, LoadParts(gateway, files), files);

    test('ouvre : texte des deux parties, audio, sans position', () async {
      final session = (await open()('c-1') as Ok<BookSession, Failure>).value;

      expect(
        session.text.words.map((x) => x.text).join(' '),
        'Le droit civil. Il règle les contrats. Fin',
      );
      expect(session.text.words[4].startMs, 4000, reason: 'décalé');
      expect(session.parts.map((p) => (p.index, p.startMs)), [
        (0, 0),
        (1, 4000),
      ]);
      expect(session.resumeAt, isNull);
    });

    test(
      'reprend à la position la plus récente (serveur ou appareil)',
      () async {
        store.position = ReadingPosition(
          wordIndex: 2,
          audioMs: 2000,
          recordedAt: DateTime.utc(2026, 10, 2),
        );
        gateway.remote = ReadingPosition(
          wordIndex: 5,
          audioMs: 5000,
          recordedAt: DateTime.utc(2026, 10, 3),
        );
        expect(
          (await open()('c-1') as Ok<BookSession, Failure>).value.resumeAt,
          gateway.remote,
        );

        // Serveur injoignable : la position de l'appareil suffit.
        gateway.positionCode = 'NETWORK_UNAVAILABLE';
        expect(
          (await open()('c-1') as Ok<BookSession, Failure>).value.resumeAt,
          store.position,
        );
      },
    );

    test('rien d’écoutable, manifeste ou WebVTT en échec', () async {
      gateway.current = testManifest(firstReady: false);
      expect(codeOf(await open()('c-1')), 'CONVERSION_NOT_READY');

      gateway
        ..current = testManifest()
        ..vttCode = 'TIMEOUT';
      expect(codeOf(await open()('c-1')), 'TIMEOUT');

      gateway.manifestCode = 'UNSUPPORTED_MANIFEST';
      expect(codeOf(await open()('c-1')), 'UNSUPPORTED_MANIFEST');
    });

    test('LoadParts à partir d’une partie (aperçu)', () async {
      final loaded =
          (await LoadParts(gateway, files)(testManifest(), fromIndex: 1)
                  as Ok<LoadedParts, Failure>)
              .value;
      expect(loaded.audio.map((p) => p.index), [1]);
      expect(loaded.words.first.text, 'règle');
    });

    test('SavePosition écrit sur l’appareil puis envoie', () async {
      final clock = FixedClock(DateTime.utc(2026, 10, 16, 8));
      await SavePosition(store, gateway, clock)(
        'c-1',
        wordIndex: 3,
        audioMs: 3200,
      );
      expect(store.position?.recordedAt, clock.instant);
      expect(gateway.saved.single.audioMs, 3200);

      await ClearPositions(store)();
      expect(store.position, isNull);
    });
  });
}
