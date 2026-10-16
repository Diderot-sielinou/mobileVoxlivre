import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/application/load_conversion_options.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// Les voix, dans l'ordre proposé (choix de la voix par défaut, Profil).
final class LoadVoices {
  const LoadVoices(this._gateway);

  final ConversionGateway _gateway;

  Future<Result<List<Voice>, Failure>> call() async =>
      switch (await _gateway.voices()) {
        Ok(:final value) => Result.ok(sortVoices(value)),
        Err(:final error) => Result.err(error),
      };
}
