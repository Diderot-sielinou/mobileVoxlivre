import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/infrastructure/api_player_gateway.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_position_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';
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
}
