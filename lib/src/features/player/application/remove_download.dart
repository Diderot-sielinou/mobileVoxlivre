import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Retire l'audio d'un livre du téléphone (ADR-0011) ; le livre reste dans
/// la bibliothèque et se retélécharge.
final class RemoveDownload {
  const RemoveDownload(this._files);

  final BookFiles _files;

  Future<void> call(String conversionId) => _files.remove(conversionId);
}
