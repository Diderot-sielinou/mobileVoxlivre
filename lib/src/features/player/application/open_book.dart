import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/domain/book_session.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

/// Rien à écouter encore (aucune partie prête).
final class NothingToPlay extends Failure {
  const NothingToPlay() : super('CONVERSION_NOT_READY');
}

/// Ouvre un livre (ADR-0010) : manifeste, parties écoutables et leurs mots,
/// puis la position de reprise — la plus récente entre l'appareil et le
/// serveur (un serveur injoignable n'empêche pas d'écouter).
final class OpenBook {
  const OpenBook(this._gateway, this._positions, this._loadParts);

  final PlayerGateway _gateway;
  final PositionStore _positions;
  final LoadParts _loadParts;

  Future<Result<BookSession, Failure>> call(String conversionId) async {
    final manifest = await _gateway.manifest(conversionId);
    switch (manifest) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final m):
        if (m.playableParts.isEmpty) return const Result.err(NothingToPlay());
        final (loaded, local, remote) = await (
          _loadParts(m),
          _positions.read(conversionId),
          _gateway.position(conversionId),
        ).wait;
        switch (loaded) {
          case Err(:final error):
            return Result.err(error);
          case Ok(value: final parts):
            final fromServer = switch (remote) {
              Ok(:final value) => value,
              Err() => null,
            };
            return Result.ok(
              BookSession(
                manifest: m,
                text: BookText(parts.words, [
                  for (final part in m.parts) ...part.pageStarts,
                ]),
                parts: parts.audio,
                resumeAt: ReadingPosition.latest(local, fromServer),
              ),
            );
        }
    }
  }
}
