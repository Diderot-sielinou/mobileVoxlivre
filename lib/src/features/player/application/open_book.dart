import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/domain/book_session.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

/// Rien à écouter encore (aucune partie prête).
final class NothingToPlay extends Failure {
  const NothingToPlay() : super('CONVERSION_NOT_READY');
}

/// Attente maximale de la position du serveur pour un livre téléchargé :
/// hors ligne, on n'attend pas le réseau pour écouter.
const offlinePositionWait = Duration(seconds: 3);

/// Ouvre un livre (ADR-0010) : manifeste, parties écoutables et leurs mots,
/// puis la position de reprise — la plus récente entre l'appareil et le
/// serveur (un serveur injoignable n'empêche pas d'écouter). Un livre
/// téléchargé s'ouvre depuis l'appareil, sans réseau (ADR-0011).
final class OpenBook {
  const OpenBook(this._gateway, this._positions, this._loadParts, this._files);

  final PlayerGateway _gateway;
  final PositionStore _positions;
  final LoadParts _loadParts;
  final BookFiles _files;

  Future<Result<BookSession, Failure>> call(String conversionId) async {
    final stored = await _files.read(conversionId);
    final offline = stored != null && stored.complete;
    final manifest = offline
        ? Result<Manifest, Failure>.ok(stored.manifest)
        : await _gateway.manifest(conversionId);
    switch (manifest) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final m):
        if (m.playableParts.isEmpty) return const Result.err(NothingToPlay());
        final (loaded, local, remote) = await (
          _loadParts(m),
          _positions.read(conversionId),
          _remotePosition(conversionId, offline: offline),
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

  Future<Result<ReadingPosition?, Failure>> _remotePosition(
    String conversionId, {
    required bool offline,
  }) {
    final request = _gateway.position(conversionId);
    if (!offline) return request;
    return request.timeout(
      offlinePositionWait,
      onTimeout: () => const Result.err(_Timeout()),
    );
  }
}

final class _Timeout extends Failure {
  const _Timeout() : super('TIMEOUT');
}
