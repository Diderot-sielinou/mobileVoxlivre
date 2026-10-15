import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';
import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

import '../auth/fakes.dart';

const amina = Voice(
  id: 'fr-f2',
  label: 'Amina',
  tier: VoiceTier.standard,
  isDefault: true,
);
const marc = Voice(
  id: 'fr-m2',
  label: 'Marc',
  tier: VoiceTier.standard,
  female: false,
);
const lea = Voice(id: 'fr-f1', label: 'Léa', tier: VoiceTier.natural);

/// Solde de test : 50 000 unités gratuites, rien d'autre.
UnitsAccount unitsAccount({
  int free = 50000,
  int pass = 0,
  int credits = 0,
  int maxChars = 1000000,
}) => UnitsAccount(
  freeRemaining: free,
  passRemaining: pass,
  credits: credits,
  maxCharsPerConversion: maxChars,
  standardWeight: 1,
  naturalWeight: 4,
);

Conversion conversion(
  ConversionStage stage, {
  String id = 'c-1',
  int segmentsDone = 0,
  int? segmentCount,
  int partsReady = 0,
  int? partCount,
  String? failureReason,
}) => Conversion(
  id: id,
  documentId: 'a',
  voiceId: 'fr-f2',
  stage: stage,
  segmentsDone: segmentsDone,
  segmentCount: segmentCount,
  partsReady: partsReady,
  partCount: partCount,
  failureReason: failureReason,
);

final class _DetailedFailure extends Failure {
  const _DetailedFailure(super.code, Map<String, Object?> details)
    : super(details: details);
}

/// Backend de conversion en mémoire : [states] est la suite des états
/// rendus par `fetch` (le dernier se répète).
final class FakeConversionGateway implements ConversionGateway {
  FakeConversionGateway({
    this.voiceList = const [lea, marc, amina],
    UnitsAccount? account,
    List<Conversion>? states,
  }) : units = account ?? unitsAccount(),
       states = states ?? [conversion(ConversionStage.queued)];

  List<Voice> voiceList;
  UnitsAccount units;
  List<Conversion> states;
  String? failure;
  String? startFailure;
  Map<String, Object?> startDetails = const {};
  final started = <(String, String)>[];
  int fetches = 0;

  @override
  Future<Result<List<Voice>, Failure>> voices() async => failure == null
      ? Result.ok(voiceList)
      : Result.err(FakeFailure(failure!));

  @override
  Future<Result<UnitsAccount, Failure>> account() async =>
      failure == null ? Result.ok(units) : Result.err(FakeFailure(failure!));

  @override
  Future<Result<Conversion, Failure>> start(
    String documentId,
    String voiceId,
  ) async {
    if (startFailure case final code?) {
      return Result.err(_DetailedFailure(code, startDetails));
    }
    started.add((documentId, voiceId));
    return Result.ok(states.first);
  }

  @override
  Future<Result<Conversion, Failure>> fetch(String conversionId) async {
    if (failure case final code?) return Result.err(FakeFailure(code));
    final state = states[fetches < states.length ? fetches : states.length - 1];
    fetches++;
    return Result.ok(state);
  }
}
