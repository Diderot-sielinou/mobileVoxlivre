import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/infrastructure/api_player_gateway.dart';
import 'package:voxlivre/src/features/player/infrastructure/device_book_files.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_bookmark_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_position_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/manifest_json.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';
import 'package:voxlivre/src/features/player/infrastructure/uuid_ids.dart';
import 'package:voxlivre/src/shared/http/signed_download.dart';

import '../../../helpers/fake_http.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

Map<String, Object?> wireManifest({int version = 1}) => {
  'version': version,
  'conversionId': 'c-1',
  'documentId': 'd-1',
  'voiceId': 'fr-f2',
  'textRevision': 1,
  'complete': false,
  'durationMs': null,
  'partCount': 2,
  'urlsExpireAt': '2026-10-16T09:00:00.000Z',
  'parts': [
    {
      'index': 0,
      'status': 'ready',
      'firstWordIndex': 0,
      'durationMs': 120000,
      'startMs': 0,
      'wordCount': 300,
      'pageStarts': [
        {'page': 1, 'wordIndex': 0},
      ],
      'audio': {
        'name': 'part-0.mp3',
        'bytes': 9,
        'sha256': 'aa',
        'url': 'https://s.test/p0.mp3?sig=1',
      },
      'vtt': {
        'name': 'part-0.vtt',
        'bytes': 9,
        'sha256': 'bb',
        'url': 'https://s.test/p0.vtt?sig=1',
      },
    },
    {
      'index': 1,
      'status': 'pending',
      'firstWordIndex': 300,
      'durationMs': null,
      'startMs': null,
      'wordCount': null,
      'pageStarts': <Object?>[],
      'audio': null,
      'vtt': null,
    },
  ],
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('ApiPlayerGateway', () {
    ApiPlayerGateway gatewayOn(FakeHttp api, [FakeHttp? storage]) =>
        ApiPlayerGateway(
          api.client(),
          SignedDownload(
            Dio()..httpClientAdapter = (storage ?? FakeHttp((_) => reply(200))),
          ),
        );

    test('lit le manifeste : parties, pages, fichiers', () async {
      final api = FakeHttp((_) => reply(200, wireManifest()));

      final manifest =
          (await gatewayOn(api).manifest('c-1') as Ok<Manifest, Failure>).value;

      expect(api.requests.single.path, '/v1/conversions/c-1/manifest');
      expect(manifest.complete, isFalse);
      expect(manifest.urlsExpireAt, DateTime.utc(2026, 10, 16, 9));
      expect(manifest.playableParts.single.audio?.url?.host, 's.test');
      expect(manifest.parts.first.pageStarts.single, (page: 1, wordIndex: 0));
      expect(manifest.parts.last.ready, isFalse);
    });

    test('version inconnue ou forme cassée : à mettre à jour', () async {
      expect(
        codeOf(
          await gatewayOn(
            FakeHttp((_) => reply(200, wireManifest(version: 2))),
          ).manifest('c-1'),
        ),
        'UNSUPPORTED_MANIFEST',
      );
      expect(
        codeOf(
          await gatewayOn(
            FakeHttp((_) => reply(200, {'version': 1, 'parts': 'x'})),
          ).manifest('c-1'),
        ),
        'UNSUPPORTED_MANIFEST',
      );
      expect(
        codeOf(
          await gatewayOn(
            FakeHttp(
              (_) =>
                  reply(409, {'status': 409, 'code': 'CONVERSION_NOT_READY'}),
            ),
          ).manifest('c-1'),
        ),
        'CONVERSION_NOT_READY',
      );
    });

    test('position : absente (404) = jamais commencée ; envoi', () async {
      var stored = false;
      final api = FakeHttp(
        (r) => r.method == 'PUT'
            ? reply(200, {'applied': true})
            : stored
            ? reply(200, {
                'conversionId': 'c-1',
                'wordIndex': 42,
                'audioMs': 9000,
                'recordedAt': '2026-10-16T07:00:00.000Z',
                'updatedAt': '2026-10-16T07:00:01.000Z',
              })
            : reply(404, {'status': 404, 'code': 'READING_POSITION_NOT_FOUND'}),
      );
      final gateway = gatewayOn(api);

      expect(
        (await gateway.position('c-1') as Ok<ReadingPosition?, Failure>).value,
        isNull,
      );
      await gateway.savePosition(
        'c-1',
        ReadingPosition(
          wordIndex: 42,
          audioMs: 9000,
          recordedAt: DateTime.utc(2026, 10, 16, 7),
        ),
      );
      expect(api.requests.last.data, {
        'wordIndex': 42,
        'audioMs': 9000,
        'recordedAt': '2026-10-16T07:00:00.000Z',
      });
      stored = true;
      final position =
          (await gateway.position('c-1') as Ok<ReadingPosition?, Failure>)
              .value!;
      expect((position.wordIndex, position.audioMs), (42, 9000));
      expect(position.recordedAt, DateTime.utc(2026, 10, 16, 7));

      final down = gatewayOn(FakeHttp((_) => reply(503, {'status': 503})));
      expect(codeOf(await down.position('c-1')), 'SERVER_ERROR');
    });

    test('WebVTT lu par URL signée, sans jeton', () async {
      final storage = FakeHttp((_) => reply(200, 'WEBVTT'));
      final api = FakeHttp((_) => reply(200));
      final result = await gatewayOn(api, storage).vtt(
        Uri.parse('https://s.test/p0.vtt?sig=1'),
      );
      expect(codeOf(result), isNull);
      expect(
        storage.requests.single.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
    });
  });

  group('marque-pages', () {
    final at = DateTime.utc(2026, 10, 16, 9, 30);
    final mark = Bookmark(
      id: 'b-1',
      documentId: 'd-1',
      pageNumber: 2,
      wordIndex: 1,
      excerpt: 'les contrats.',
      note: 'à revoir',
      createdAt: at,
      updatedAt: at,
    );
    Map<String, Object?> wire({String? deletedAt}) => {
      'id': 'b-1',
      'pageNumber': 2,
      'wordIndex': 1,
      'excerpt': 'les contrats du serveur',
      'note': 'à revoir',
      'needsReview': true,
      'createdAt': '2026-10-16T09:30:00.000Z',
      'updatedAt': '2026-10-16T09:30:00.000Z',
      'deletedAt': deletedAt,
    };
    ApiPlayerGateway on(FakeHttp api) => ApiPlayerGateway(
      api.client(),
      SignedDownload(Dio()..httpClientAdapter = FakeHttp((_) => reply(200))),
    );

    test('liste, envoi, suppression : chemins, corps, réponse', () async {
      final api = FakeHttp(
        (r) => switch (r.method) {
          'GET' => reply(200, {
            'items': [wire()],
          }),
          'PUT' => reply(201, wire(deletedAt: '2026-10-16T10:00:00.000Z')),
          _ => reply(204),
        },
      );
      final gateway = on(api);

      final list =
          (await gateway.bookmarks('d-1') as Ok<List<Bookmark>, Failure>).value;
      expect(list.single.excerpt, 'les contrats du serveur');
      expect(list.single.needsReview, isTrue);
      expect(list.single.documentId, 'd-1');

      final kept =
          (await gateway.putBookmark(mark) as Ok<Bookmark, Failure>).value;
      expect(api.requests[1].path, '/v1/documents/d-1/bookmarks/b-1');
      expect(api.requests[1].data, {
        'pageNumber': 2,
        'wordIndex': 1,
        'note': 'à revoir',
        'updatedAt': '2026-10-16T09:30:00.000Z',
      });
      expect(kept.deleted, isTrue, reason: 'suppression plus récente');

      expect(
        codeOf(await gateway.deleteBookmark(mark.copyWith(deletedAt: at))),
        isNull,
      );
      expect(api.requests[2].method, 'DELETE');
      expect(api.requests[2].queryParameters, {
        'deletedAt': '2026-10-16T09:30:00.000Z',
      });
    });

    test('422 et 409 : refus définitif ; 503 et réseau : passager', () async {
      Future<Failure?> put(int status) async => switch (await on(
        FakeHttp((_) => reply(status, {'status': status, 'code': 'X_$status'})),
      ).putBookmark(mark)) {
        Err(:final error) => error,
        Ok() => null,
      };
      expect(await put(422), isA<BookmarkRejected>());
      expect((await put(409))?.code, 'X_409');
      expect(await put(409), isA<BookmarkRejected>());
      expect(await put(503), isNot(isA<BookmarkRejected>()));
    });

    test('sur l’appareil : actifs triés, traces, à envoyer, effacer', () async {
      final db = PlayerDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = DriftBookmarkStore(db);
      await store.save(mark.copyWith(pending: true));
      await store.save(
        Bookmark(
          id: 'b-0',
          documentId: 'd-1',
          pageNumber: 1,
          wordIndex: 3,
          excerpt: 'Le droit',
          note: '',
          createdAt: at,
          updatedAt: at,
        ),
      );
      List<String> ids(List<Bookmark> list) => [for (final b in list) b.id];

      expect(ids(await store.watch('d-1').first), ['b-0', 'b-1']);
      expect(ids(await store.pending()), ['b-1']);
      final back = (await store.all('d-1')).firstWhere((b) => b.id == 'b-1');
      expect(back.updatedAt, at);
      expect(back.updatedAt.isUtc, isTrue);
      expect(back.note, 'à revoir');

      // Supprimé : plus dans la liste, la trace reste.
      await store.save(back.copyWith(deletedAt: at));
      expect(ids(await store.watch('d-1').first), ['b-0']);
      expect(await store.all('d-1'), hasLength(2));

      await store.remove('b-1');
      expect(await store.all('d-1'), hasLength(1));
      await store.clear();
      expect(await store.all('d-1'), isEmpty);
    });

    test('UUID v4 différents', () {
      const ids = UuidIds();
      final a = ids.newId();
      expect(a, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(a, isNot(ids.newId()));
    });
  });

  group('SignedDownload', () {
    Future<String?> get(FakeHttp http) async => codeOf(
      await SignedDownload(Dio()..httpClientAdapter = http).text(
        Uri.parse('https://s.test/x'),
      ),
    );

    test('statut et réseau → code', () async {
      expect(await get(FakeHttp((_) => reply(403))), 'FORBIDDEN');
      expect(
        await get(
          FakeHttp(
            (r) => throw DioException.connectionError(
              requestOptions: r,
              reason: 'hors ligne',
            ),
          ),
        ),
        'NETWORK_UNAVAILABLE',
      );
      expect(
        await get(
          FakeHttp(
            (r) => throw DioException.receiveTimeout(
              timeout: Duration.zero,
              requestOptions: r,
            ),
          ),
        ),
        'TIMEOUT',
      );
      expect(SignedDownload.create(), isA<SignedDownload>());
    });
  });

  test('positions sur l’appareil : écrire, relire en UTC, effacer', () async {
    final db = PlayerDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftPositionStore(db);
    final at = DateTime.utc(2026, 10, 16, 7, 30);

    expect(await store.read('c-1'), isNull);
    await store.write(
      'c-1',
      ReadingPosition(wordIndex: 1, audioMs: 10, recordedAt: at),
    );
    await store.write(
      'c-1',
      ReadingPosition(wordIndex: 2, audioMs: 20, recordedAt: at),
    );
    final read = (await store.read('c-1'))!;
    expect((read.wordIndex, read.audioMs, read.recordedAt), (2, 20, at));
    expect(read.recordedAt.isUtc, isTrue);

    await store.clear();
    expect(await store.read('c-1'), isNull);
  });

  group('livres hors ligne', () {
    late Directory temp;
    late PlayerDatabase db;
    late DeviceBookFiles files;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('voxlivre-books');
      db = PlayerDatabase(NativeDatabase.memory());
      files = DeviceBookFiles(db, () async => temp);
    });

    tearDown(() async {
      await db.close();
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    test('télécharger dans un fichier, sans jeton, puis effacer', () async {
      final storage = FakeHttp((_) => reply(200, 'MP3'));
      final gateway = ApiPlayerGateway(
        FakeHttp((_) => reply(200)).client(),
        SignedDownload(Dio()..httpClientAdapter = storage),
      );
      final path = await files.pathOf('c-1', 0, PartFile.audio);
      var received = 0;

      final result = await gateway.download(
        Uri.parse('https://s.test/p0.mp3?sig=1'),
        path,
        onBytes: (b) => received = b,
      );

      expect(codeOf(result), isNull);
      expect(path, endsWith('/books/c-1/part-0.mp3'));
      final bytes = File(path).readAsBytesSync();
      expect(received, bytes.length);
      expect(
        await files.matches(path, sha256.convert(bytes).toString()),
        isTrue,
      );
      expect(await files.matches(path, 'autre'), isFalse);
      await files.deleteFile(path);
      expect(await files.matches(path, 'autre'), isFalse, reason: 'absent');

      storage.respond = (_) => reply(403);
      expect(
        codeOf(await gateway.download(Uri.parse('https://s.test/x'), path)),
        'FORBIDDEN',
      );
      storage.respond = (r) => throw DioException.connectionError(
        requestOptions: r,
        reason: 'hors ligne',
      );
      expect(
        codeOf(await gateway.download(Uri.parse('https://s.test/x'), path)),
        'NETWORK_UNAVAILABLE',
      );
      // Annulé avant même de partir.
      expect(
        codeOf(
          await gateway.download(
            Uri.parse('https://s.test/x'),
            path,
            cancel: Future<void>.value(),
          ),
        ),
        'CANCELLED',
      );
    });

    test('manifeste gardé sans URL, parties vérifiées en file://', () async {
      final manifest = manifestFromJson(wireManifest());
      expect(await files.read('c-1'), isNull);
      final seen = <Set<String>>[];
      final watching = files.watchComplete().listen(seen.add);

      await files.save('c-1', manifest);
      final vtt = await files.pathOf('c-1', 0, PartFile.vtt);
      File(vtt).writeAsStringSync('WEBVTT');
      await files.markVerified('c-1', 0);
      var stored = (await files.read('c-1'))!;
      expect(stored.complete, isFalse);
      expect(stored.verified, {0});
      expect(stored.manifest.parts.first.vtt!.url, Uri.file(vtt));
      expect(stored.manifest.parts.last.audio, isNull, reason: 'en attente');
      expect(stored.manifest.urlsExpireAt.year, 9999);
      expect(await files.readText(vtt), 'WEBVTT');

      await files.markComplete('c-1');
      stored = (await files.read('c-1'))!;
      expect(stored.complete, isTrue);
      await pumpEventQueue();
      expect(seen.last, {'c-1'});

      await files.remove('c-1');
      expect(await files.read('c-1'), isNull);
      expect(File(vtt).existsSync(), isFalse);

      await files.save('c-2', manifest);
      await files.pathOf('c-2', 0, PartFile.audio);
      await files.clear();
      expect(await files.read('c-2'), isNull);
      expect(Directory('${temp.path}/books').existsSync(), isFalse);
      await watching.cancel();
    });

    test('le manifeste relu est celui écrit (sans URL)', () {
      final manifest = manifestFromJson(wireManifest());
      final json = manifestToJson(manifest);
      expect(jsonEncode(json), isNot(contains('https://')));
      final back = manifestFromJson(json);
      expect(back.parts.first.audio!.sha256, 'aa');
      expect(back.parts.first.pageStarts.single, (page: 1, wordIndex: 0));
      expect(back.parts.last.ready, isFalse);
      expect(back.urlsExpireAt, manifest.urlsExpireAt);
    });
  });

  test('positions : à envoyer, puis envoyées', () async {
    final db = PlayerDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = DriftPositionStore(db);
    final at = DateTime.utc(2026, 10, 16, 7, 30);
    await store.write(
      'c-1',
      ReadingPosition(wordIndex: 1, audioMs: 10, recordedAt: at),
    );
    expect((await store.pending()).keys, ['c-1']);

    // Une autre position écrite entre-temps reste à envoyer.
    await store.markSent('c-1', at.subtract(const Duration(minutes: 1)));
    expect(await store.pending(), hasLength(1));
    await store.markSent('c-1', at);
    expect(await store.pending(), isEmpty);
  });

  test(
    'positions : une position à la milliseconde se marque envoyée',
    () async {
      final db = PlayerDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = DriftPositionStore(db);
      final at = DateTime.utc(2026, 10, 16, 7, 30, 12, 345);
      await store.write(
        'c-1',
        ReadingPosition(wordIndex: 1, audioMs: 10, recordedAt: at),
      );
      await store.markSent('c-1', at);
      expect(await store.pending(), isEmpty);
    },
  );

  test(
    'migration v1 → v2 : la position reste, livres hors ligne créés',
    () async {
      final dir = await Directory.systemTemp.createTemp('voxlivre-db');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/player.sqlite');

      // Une base v1 (étape 15a) : sans `pending` ni tables des livres.
      final v2 = PlayerDatabase(NativeDatabase(file));
      await v2.customStatement('DROP TABLE bookmarks');
      await v2.customStatement('DROP TABLE downloaded_books');
      await v2.customStatement('DROP TABLE verified_parts');
      await v2.customStatement(
        'ALTER TABLE reading_positions DROP COLUMN pending',
      );
      await v2.customStatement(
        'INSERT INTO reading_positions '
        '(conversion_id, word_index, audio_ms, recorded_at) '
        "VALUES ('c-1', 4, 900, 1792135800)",
      );
      await v2.customStatement('PRAGMA user_version = 1');
      await v2.close();

      final upgraded = PlayerDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final store = DriftPositionStore(upgraded);
      expect((await store.read('c-1'))?.wordIndex, 4);
      // Déjà envoyée sous la v1 : rien à renvoyer.
      expect(await store.pending(), isEmpty);
      expect(await upgraded.select(upgraded.downloadedBooks).get(), isEmpty);
      expect(await upgraded.select(upgraded.verifiedParts).get(), isEmpty);
      expect(await upgraded.select(upgraded.bookmarks).get(), isEmpty);
    },
  );

  test('migration v2 → v3 : livres gardés, marque-pages créés', () async {
    final dir = await Directory.systemTemp.createTemp('voxlivre-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/player.sqlite');

    // Une base v2 (étape 15b) : sans `bookmarks`.
    final v3 = PlayerDatabase(NativeDatabase(file));
    await v3.customStatement('DROP TABLE bookmarks');
    await v3.customStatement(
      'INSERT INTO downloaded_books (conversion_id, manifest_json, complete) '
      "VALUES ('c-1', '{}', 1)",
    );
    await v3.customStatement('PRAGMA user_version = 2');
    await v3.close();

    final upgraded = PlayerDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(await upgraded.select(upgraded.downloadedBooks).get(), hasLength(1));
    expect(await DriftBookmarkStore(upgraded).all('d-1'), isEmpty);
  });
}
