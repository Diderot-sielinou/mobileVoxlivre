import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/clear_downloads.dart';
import 'package:voxlivre/src/features/player/application/download_book.dart';
import 'package:voxlivre/src/features/player/application/flush_positions.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/application/open_book.dart';
import 'package:voxlivre/src/features/player/application/remove_download.dart';
import 'package:voxlivre/src/features/player/application/save_position.dart';
import 'package:voxlivre/src/features/player/domain/book_session.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

import '../../../helpers/app_harness.dart';
import 'fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

/// Le manifeste de test avec d'autres empreintes (livre régénéré).
Manifest regenerated() {
  final m = testManifest();
  return Manifest(
    conversionId: m.conversionId,
    documentId: m.documentId,
    complete: true,
    partCount: m.partCount,
    urlsExpireAt: m.urlsExpireAt,
    durationMs: m.durationMs,
    parts: [
      for (final p in m.parts)
        ManifestPart(
          index: p.index,
          ready: true,
          firstWordIndex: p.firstWordIndex,
          startMs: p.startMs,
          durationMs: p.durationMs,
          pageStarts: p.pageStarts,
          audio: ManifestFile(url: p.audio!.url, bytes: 1, sha256: 'z'),
          vtt: p.vtt,
        ),
    ],
  );
}

void main() {
  late FakePlayerGateway gateway;
  late MemoryBookFiles files;
  late MemoryPositionStore positions;

  setUp(() {
    gateway = FakePlayerGateway();
    files = MemoryBookFiles(gateway.disk);
    positions = MemoryPositionStore();
  });

  DownloadBook download() => DownloadBook(gateway, files);

  group('DownloadBook', () {
    test(
      'tout le livre, vérifié partie par partie, avec la progression',
      () async {
        final progress = <DownloadProgress>[];

        final result = await download()('c-1', onProgress: progress.add);

        expect(codeOf(result), isNull);
        expect(
          gateway.downloads,
          hasLength(4),
          reason: '2 parties × 2 fichiers',
        );
        final stored = (await files.read('c-1'))!;
        expect(stored.complete, isTrue);
        expect(stored.verified, {0, 1});
        expect(stored.manifest.parts.first.audio!.url!.scheme, 'file');
        expect(progress.first.bytesDone, 0);
        expect(progress.last.partsDone, 2);
        expect(progress.last.fraction, 1);
        expect(progress.last.currentPart, 2);
      },
    );

    test('coupure : seules les parties manquantes repartent', () async {
      gateway.failOnce['https://s.test/p1.mp3'] = 'NETWORK_UNAVAILABLE';
      expect(codeOf(await download()('c-1')), 'NETWORK_UNAVAILABLE');
      final partial = (await files.read('c-1'))!;
      expect(partial.complete, isFalse);
      expect(partial.verified, {0});
      expect(partial.progress.bytesDone, 2);
      expect(partial.progress.currentPart, 2);

      gateway.downloads.clear();
      expect(codeOf(await download()('c-1')), isNull);
      expect(gateway.downloads.map((u) => u.path), ['/p1.mp3', '/p1.vtt']);
    });

    test('URL expirées : le manifeste est relu une fois', () async {
      gateway.failOnce['https://s.test/p0.mp3'] = 'FORBIDDEN';
      expect(codeOf(await download()('c-1')), isNull);
      expect(gateway.manifests, 2);

      // Deux refus de suite : on s'arrête.
      await files.remove('c-1');
      gateway
        ..failOnce['https://s.test/p0.mp3'] = 'FORBIDDEN'
        ..failOnce['https://s.test/p0.vtt'] = 'FORBIDDEN';
      expect(codeOf(await download()('c-1')), 'FORBIDDEN');
    });

    test('empreinte fausse : un second essai, puis abandon', () async {
      gateway.corrupt.add('https://s.test/p0.mp3');
      expect(codeOf(await download()('c-1')), 'DOWNLOAD_CORRUPT');
      expect(
        gateway.downloads.where((u) => u.path == '/p0.mp3'),
        hasLength(2),
      );
      expect(gateway.disk, isEmpty, reason: 'fichier abîmé jeté');
    });

    test('annulé : ce qui est vérifié reste', () async {
      final cancel = Completer<void>();
      gateway.hold = Completer<void>();
      final running = download()('c-1', cancel: cancel.future);
      await Future<void>.delayed(Duration.zero);
      cancel.complete();
      expect(codeOf(await running), 'CANCELLED');
    });

    test('conversion pas finie, manifeste injoignable', () async {
      gateway.current = testManifest(secondReady: false);
      expect(codeOf(await download()('c-1')), 'CONVERSION_NOT_READY');
      gateway.manifestCode = 'NETWORK_UNAVAILABLE';
      expect(codeOf(await download()('c-1')), 'NETWORK_UNAVAILABLE');
    });

    test('livre régénéré : on repart de zéro', () async {
      await download()('c-1');
      gateway
        ..current = regenerated()
        ..downloads.clear();
      // Le nouveau MP3 de la partie 0 a l'empreinte « z » : refusé, mais
      // l'ancien livre a bien été retiré avant.
      gateway.corrupt.clear();
      expect(codeOf(await download()('c-1')), 'DOWNLOAD_CORRUPT');
      expect(gateway.downloads.first.path, '/p0.mp3');
      expect((await files.read('c-1'))!.complete, isFalse);
    });

    test('retirer, tout effacer', () async {
      await download()('c-1');
      await RemoveDownload(files)('c-1');
      expect(await files.read('c-1'), isNull);
      expect(gateway.disk, isEmpty);

      await download()('c-1');
      await ClearDownloads(files)();
      expect(files.clears, 1);
      expect(await files.read('c-1'), isNull);
    });
  });

  group('lecture hors ligne', () {
    OpenBook open() =>
        OpenBook(gateway, positions, LoadParts(gateway, files), files);

    test('livre téléchargé : ni manifeste ni WebVTT du réseau', () async {
      await download()('c-1');
      gateway
        ..manifests = 0
        ..vttCode = 'NETWORK_UNAVAILABLE'
        ..positionCode = 'NETWORK_UNAVAILABLE';

      final session = (await open()('c-1') as Ok<BookSession, Failure>).value;

      expect(gateway.manifests, 0);
      expect(session.parts.map((p) => p.url.scheme), ['file', 'file']);
      expect(session.text.words.first.text, 'Le');
      expect(session.manifest.urlsExpireAt.year, 9999);
    });

    testWidgets('serveur muet : la position de l’appareil, après 3 s', (
      tester,
    ) async {
      await download()('c-1');
      positions.position = ReadingPosition(
        wordIndex: 2,
        audioMs: 2000,
        recordedAt: DateTime.utc(2026, 10, 16),
      );
      gateway.positionHold = Completer<void>();

      var done = false;
      final opening = open()('c-1').whenComplete(() => done = true);
      await tester.pump(offlinePositionWait - const Duration(seconds: 1));
      expect(done, isFalse);
      await tester.pump(const Duration(seconds: 1));
      final session = (await opening as Ok<BookSession, Failure>).value;
      expect(session.resumeAt?.audioMs, 2000);
    });
  });

  group('positions à envoyer', () {
    final clock = FixedClock(DateTime.utc(2026, 10, 16, 8));

    test('envoyée : plus à envoyer ; hors ligne : gardée', () async {
      final save = SavePosition(positions, gateway, clock);
      await save('c-1', wordIndex: 1, audioMs: 100);
      expect(await positions.pending(), isEmpty);

      gateway.saveCode = 'NETWORK_UNAVAILABLE';
      await save('c-2', wordIndex: 2, audioMs: 200);
      expect((await positions.pending()).keys, ['c-2']);
    });

    test('FlushPositions envoie, et s’arrête au premier échec', () async {
      final at = DateTime.utc(2026, 10, 16, 7);
      positions.unsent.addAll({
        'c-1': ReadingPosition(wordIndex: 1, audioMs: 1, recordedAt: at),
        'c-2': ReadingPosition(wordIndex: 2, audioMs: 2, recordedAt: at),
      });
      gateway.saveCode = 'NETWORK_UNAVAILABLE';
      final flush = FlushPositions(positions, gateway);
      expect(await flush(), 0);
      expect(positions.unsent, hasLength(2));

      gateway.saveCode = null;
      expect(await flush(), 2);
      expect(positions.unsent, isEmpty);
      expect(gateway.saved.map((p) => p.wordIndex), [1, 2]);
    });
  });
}
