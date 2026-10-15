import 'package:voxlivre/src/features/library/domain/document_import.dart';

/// Choisit un PDF ; [discard] efface la copie locale d'un fichier
/// abandonné (autre choix, écran quitté) : c'est un document personnel.
final class PickPdf {
  const PickPdf(this._source);

  final PdfSource _source;

  Future<PickedPdf?> call() => _source.pick();

  Future<void> discard(PickedPdf file) => _source.discard(file);
}
