import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/application/fetch_conversion.dart';
import 'package:voxlivre/src/features/conversion/application/load_conversion_options.dart';
import 'package:voxlivre/src/features/conversion/application/start_conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_options.dart';
import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';
import 'package:voxlivre/src/features/conversion/infrastructure/api_conversion_gateway.dart';

import '../../../helpers/fake_http.dart';
import 'fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

Map<String, Object?> wireConversion(String status) => {
  'id': 'c-1',
  'documentId': 'a',
  'voiceId': 'fr-f2',
  'status': status,
  'reservedChars': 1000,
  'progress': {
    'segmentsDone': 3,
    'segmentCount': 10,
    'partsReady': 1,
    'partCount': 4,
  },
  'failureReason': status == 'failed' ? 'tts_rejected' : null,
  'createdAt': '2026-10-15T10:00:00.000Z',
  'updatedAt': '2026-10-15T10:01:00.000Z',
  'completedAt': null,
};

void main() {
  group('domaine', () {
    test('coût, solde utilisable par gamme, manque, plafond', () {
      final account = unitsAccount(pass: 10000, credits: 5000);

      expect(account.costFor(1000, VoiceTier.standard), 1000);
      expect(account.costFor(1000, VoiceTier.natural), 4000);
      expect(account.usableFor(VoiceTier.standard), 65000);
      expect(
        account.usableFor(VoiceTier.natural),
        15000,
        reason: 'le gratuit ne finance pas une voix naturelle',
      );
      expect(account.shortfall(60000, VoiceTier.standard), 0);
      expect(account.shortfall(10000, VoiceTier.natural), 25000);
      expect(unitsAccount(maxChars: 100).tooLong(101), isTrue);
      expect(unitsAccount(maxChars: 100).tooLong(100), isFalse);
      expect(VoiceTier.fromWire('natural'), VoiceTier.natural);
      expect(VoiceTier.fromWire('autre'), VoiceTier.standard);
    });

    test('étapes du backend, et l’étape affichée sur 4', () {
      expect(
        [
          'queued',
          'preparing',
          'synthesizing',
          'synthesized',
          'ready',
          'failed',
          'archived',
        ].map(ConversionStage.fromWire),
        ConversionStage.values,
      );
      expect(
        ConversionStage.values.map((s) => conversion(s).step),
        [1, 1, 2, 3, 4, 0, 0],
      );
      expect(
        ConversionStage.values.where((s) => s.working),
        hasLength(4),
      );
      expect(
        conversion(
          ConversionStage.synthesizing,
          segmentsDone: 3,
          segmentCount: 12,
        ).synthesisRatio,
        0.25,
      );
      expect(conversion(ConversionStage.queued).synthesisRatio, isNull);
    });
  });

  group('cas d’usage', () {
    test('options : voix par défaut, puis standard, puis naturelles', () async {
      final gateway = FakeConversionGateway();
      final result = await LoadConversionOptions(gateway)();

      final options = (result as Ok<ConversionOptions, Failure>).value;
      expect(
        options.voices.map((v) => v.label).toList(),
        ['Amina', 'Marc', 'Léa'],
      );
      expect(suggestedVoice([marc, lea])?.id, 'fr-m2');

      gateway.failure = 'NETWORK_UNAVAILABLE';
      expect(
        codeOf(await LoadConversionOptions(gateway)()),
        'NETWORK_UNAVAILABLE',
      );
    });

    test('lancer et relire passent au backend', () async {
      final gateway = FakeConversionGateway();
      expect(codeOf(await StartConversion(gateway)('a', 'fr-f2')), isNull);
      expect(gateway.started, [('a', 'fr-f2')]);
      expect(codeOf(await FetchConversion(gateway)('c-1')), isNull);
    });
  });

  group('ApiConversionGateway', () {
    test('voix, solde (deux appels) et conversion', () async {
      final http = FakeHttp(
        (r) => switch (r.path) {
          '/v1/voices' => reply(200, {
            'items': [
              {
                'id': 'fr-f1',
                'label': 'Léa',
                'gender': 'female',
                'languageCode': 'fr-FR',
                'tier': 'natural',
                'isDefault': false,
              },
              {
                'id': 'fr-m2',
                'label': 'Marc',
                'gender': 'male',
                'languageCode': 'fr-FR',
                'tier': 'standard',
                'isDefault': true,
              },
            ],
          }),
          '/v1/billing/account' => reply(200, {
            'period': '2026-10',
            'free': {'limit': 50000, 'used': 1000, 'remaining': 49000},
            'pass': {
              'endsAt': '2026-11-01T00:00:00.000Z',
              'includedUnits': 100000,
              'usedUnits': 0,
              'remainingUnits': 100000,
            },
            'nextPassStartsAt': null,
            'credits': 7,
            'maxCharsPerConversion': 2000000,
          }),
          '/v1/billing/offers' => reply(200, {
            'items': <Object?>[],
            'voiceTierWeights': {'standard': 1, 'natural': 4},
          }),
          _ when r.method == 'POST' => reply(202, wireConversion('queued')),
          _ => reply(200, wireConversion('synthesizing')),
        },
      );
      final gateway = ApiConversionGateway(http.client());

      final voices = (await gateway.voices() as Ok<List<Voice>, Failure>).value;
      expect(voices.map((v) => (v.label, v.tier, v.female, v.isDefault)), [
        ('Léa', VoiceTier.natural, true, false),
        ('Marc', VoiceTier.standard, false, true),
      ]);

      final account =
          (await gateway.account() as Ok<UnitsAccount, Failure>).value;
      expect(account.usableFor(VoiceTier.standard), 149007);
      expect(account.naturalWeight, 4);

      final started =
          (await gateway.start('a', 'fr-m2') as Ok<Conversion, Failure>).value;
      expect(http.requests.last.path, '/v1/documents/a/conversions');
      expect(http.requests.last.data, {'voiceId': 'fr-m2'});
      expect(started.stage, ConversionStage.queued);

      final fetched =
          (await gateway.fetch('c-1') as Ok<Conversion, Failure>).value;
      expect(fetched.stage, ConversionStage.synthesizing);
      expect(fetched.synthesisRatio, 0.3);
      expect((fetched.partsReady, fetched.partCount), (1, 4));
    });

    test('402 : le détail du manque arrive jusqu’à l’écran', () async {
      final http = FakeHttp(
        (r) => r.path == '/v1/billing/offers'
            ? reply(503, {'status': 503})
            : reply(402, {
                'status': 402,
                'code': 'QUOTA_EXCEEDED',
                'details': {'requested': 857200, 'usable': 375200},
              }),
      );
      final gateway = ApiConversionGateway(http.client());

      final result = await gateway.start('a', 'fr-f1');
      expect(codeOf(result), 'QUOTA_EXCEEDED');
      expect(
        (result as Err<Conversion, Failure>).error.details['requested'],
        857200,
      );
      expect(codeOf(await gateway.account()), isNotNull);
    });
  });
}
