import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Un livre complet sur le téléphone, et sa place.
typedef DownloadedBook = ({String conversionId, String documentId, int bytes});

/// Les livres téléchargés (écran « Stockage hors ligne », ADR-0014).
final class ListDownloads {
  const ListDownloads(this._files);

  final BookFiles _files;

  /// Pour chaque ensemble de livres complets (à chaque changement).
  Stream<List<DownloadedBook>> call() =>
      _files.watchComplete().asyncMap((ids) async {
        final books = <DownloadedBook>[];
        for (final id in ids) {
          final stored = await _files.read(id);
          if (stored == null || !stored.complete) continue;
          books.add((
            conversionId: id,
            documentId: stored.manifest.documentId,
            bytes: manifestBytes(stored.manifest),
          ));
        }
        books.sort((a, b) => b.bytes.compareTo(a.bytes));
        return books;
      });
}
