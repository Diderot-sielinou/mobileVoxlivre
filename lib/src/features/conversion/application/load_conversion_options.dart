import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_options.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// Voix et solde, lus en même temps. Voix par défaut d'abord, puis les
/// standard (les moins chères), puis les naturelles.
final class LoadConversionOptions {
  const LoadConversionOptions(this._gateway);

  final ConversionGateway _gateway;

  Future<Result<ConversionOptions, Failure>> call() async {
    final (voices, account) = await (
      _gateway.voices(),
      _gateway.account(),
    ).wait;
    switch ((voices, account)) {
      case (Err(:final error), _) || (_, Err(:final error)):
        return Result.err(error);
      case (Ok(value: final list), Ok(value: final units)):
        return Result.ok(
          ConversionOptions(voices: sortVoices(list), account: units),
        );
    }
  }
}

/// Voix par défaut d'abord, puis les standard, puis les naturelles.
List<Voice> sortVoices(List<Voice> voices) => [...voices]
  ..sort((a, b) {
    if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
    return a.tier.index.compareTo(b.tier.index);
  });

/// La voix proposée d'abord : celle choisie dans le Profil si elle existe
/// encore (ADR-0014), sinon la première (défaut du serveur).
Voice? suggestedVoice(List<Voice> voices, {String? preferred}) =>
    voices.where((v) => v.id == preferred).firstOrNull ?? voices.firstOrNull;
