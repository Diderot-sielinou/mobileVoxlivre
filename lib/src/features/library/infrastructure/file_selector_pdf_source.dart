import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';

/// [PdfSource] : le sélecteur du système (`file_selector`, ADR-0007). Sur
/// Android, le fichier choisi est copié dans le cache de l'app ; seule
/// cette copie est effacée, jamais l'original.
final class FileSelectorPdfSource implements PdfSource {
  const FileSelectorPdfSource();

  static final _log = Logger('library');
  static const _pdf = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );

  /// `%PDF-`
  static const _signature = [0x25, 0x50, 0x44, 0x46, 0x2D];

  @override
  Future<PickedPdf?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [_pdf]);
    if (file == null) return null;
    final head = <int>[];
    await for (final chunk in file.openRead(0, _signature.length)) {
      head.addAll(chunk);
    }
    return PickedPdf(
      name: file.name,
      path: file.path,
      sizeBytes: await file.length(),
      isPdf:
          head.length == _signature.length &&
          [
            for (var i = 0; i < head.length; i++) head[i] == _signature[i],
          ].every((same) => same),
    );
  }

  @override
  Future<void> discard(PickedPdf file) async {
    final cache = (await getTemporaryDirectory()).path;
    final copy = File(file.path);
    if (!copy.path.startsWith('$cache${Platform.pathSeparator}')) return;
    try {
      // La copie est seule dans un dossier temporaire à son nom.
      final folder = copy.parent;
      await (folder.path == cache ? copy : folder).delete(recursive: true);
    } on FileSystemException catch (e) {
      _log.warning('copie du PDF non effacée : ${e.osError?.errorCode}');
    }
  }
}
