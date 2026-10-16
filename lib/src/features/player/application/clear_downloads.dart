import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Fin de session : tous les livres téléchargés partent.
final class ClearDownloads {
  const ClearDownloads(this._files);

  final BookFiles _files;

  Future<void> call() => _files.clear();
}
