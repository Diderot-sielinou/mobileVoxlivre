import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';
import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

typedef _Json = Map<String, Object?>;

/// [ConversionGateway] sur `voxlivre-api` (ADR-0008). Une réponse de forme
/// inattendue devient `UNEXPECTED_RESPONSE` (ApiClient), jamais un plantage.
final class ApiConversionGateway implements ConversionGateway {
  const ApiConversionGateway(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<Voice>, Failure>> voices() => _api.get(
    '/v1/voices',
    decode: (r) => [
      for (final v
          in ((r.json! as _Json)['items']! as List<Object?>).cast<_Json>())
        Voice(
          id: v['id']! as String,
          label: v['label']! as String,
          tier: VoiceTier.fromWire(v['tier']! as String),
          female: v['gender'] != 'male',
          isDefault: v['isDefault'] == true,
        ),
    ],
  );

  @override
  Future<Result<UnitsAccount, Failure>> account() async {
    final (account, offers) = await (
      _api.get('/v1/billing/account', decode: (r) => r.json! as _Json),
      _api.get('/v1/billing/offers', decode: (r) => r.json! as _Json),
    ).wait;
    switch ((account, offers)) {
      case (Err(:final error), _) || (_, Err(:final error)):
        return Result.err(error);
      case (Ok(value: final a), Ok(value: final o)):
        final free = a['free']! as _Json;
        final pass = a['pass'] as _Json?;
        final weights = o['voiceTierWeights']! as _Json;
        return Result.ok(
          UnitsAccount(
            freeRemaining: free['remaining']! as int,
            passRemaining: (pass?['remainingUnits'] as int?) ?? 0,
            credits: a['credits']! as int,
            maxCharsPerConversion: a['maxCharsPerConversion']! as int,
            standardWeight: weights['standard']! as int,
            naturalWeight: weights['natural']! as int,
          ),
        );
    }
  }

  @override
  Future<Result<Conversion, Failure>> start(
    String documentId,
    String voiceId,
  ) => _api.post(
    '/v1/documents/$documentId/conversions',
    body: {'voiceId': voiceId},
    decode: (r) => _conversion(r.json! as _Json),
  );

  @override
  Future<Result<Conversion, Failure>> fetch(String conversionId) => _api.get(
    '/v1/conversions/$conversionId',
    decode: (r) => _conversion(r.json! as _Json),
  );

  static Conversion _conversion(_Json json) {
    final progress = json['progress']! as _Json;
    return Conversion(
      id: json['id']! as String,
      documentId: json['documentId']! as String,
      voiceId: json['voiceId']! as String,
      stage: ConversionStage.fromWire(json['status']! as String),
      segmentsDone: progress['segmentsDone']! as int,
      segmentCount: progress['segmentCount'] as int?,
      partsReady: progress['partsReady']! as int,
      partCount: progress['partCount'] as int?,
      failureReason: json['failureReason'] as String?,
    );
  }
}
