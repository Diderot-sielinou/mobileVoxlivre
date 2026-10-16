import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/book_session.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/timed_word.dart';
import 'package:voxlivre/src/features/player/domain/webvtt.dart';

/// Charge les parties écoutables d'un manifeste, à partir d'un index :
/// l'audio à jouer et les mots de leur WebVTT (instants absolus). Un livre
/// téléchargé a des URL `file://` : son WebVTT se lit sur l'appareil.
final class LoadParts {
  const LoadParts(this._gateway, this._files);

  final PlayerGateway _gateway;
  final BookFiles _files;

  Future<Result<String, Failure>> _vtt(Uri url) async => url.isScheme('file')
      ? Result.ok(await _files.readText(url.toFilePath()))
      : _gateway.vtt(url);

  Future<Result<LoadedParts, Failure>> call(
    Manifest manifest, {
    int fromIndex = 0,
  }) async {
    final parts = [
      for (final part in manifest.playableParts)
        if (part.index >= fromIndex) part,
    ];
    final texts = await Future.wait(
      parts.map((part) => _vtt(part.vtt!.url!)),
    );
    final words = <TimedWord>[];
    for (var i = 0; i < parts.length; i++) {
      switch (texts[i]) {
        case Err(:final error):
          return Result.err(error);
        case Ok(:final value):
          words.addAll(parseWebVtt(value, offsetMs: parts[i].startMs!));
      }
    }
    return Result.ok(
      LoadedParts(
        audio: [
          for (final part in parts)
            AudioPart(
              index: part.index,
              url: part.audio!.url!,
              startMs: part.startMs!,
            ),
        ],
        words: words,
      ),
    );
  }
}
