import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// Seul un livre entièrement converti se télécharge.
final class NotDownloadable extends Failure {
  const NotDownloadable() : super('CONVERSION_NOT_READY');
}

/// Un fichier reçu n'a pas l'empreinte annoncée, même après un second essai.
final class CorruptDownload extends Failure {
  const CorruptDownload() : super('DOWNLOAD_CORRUPT');
}

/// Télécharge un livre pour l'écouter sans réseau (ADR-0011) : seules les
/// parties pas encore vérifiées partent ; chaque fichier est contrôlé par
/// son SHA-256. URL expirées : le manifeste est relu une fois.
final class DownloadBook {
  const DownloadBook(this._gateway, this._files);

  final PlayerGateway _gateway;
  final BookFiles _files;

  Future<Result<void, Failure>> call(
    String conversionId, {
    void Function(DownloadProgress progress)? onProgress,
    Future<void>? cancel,
  }) async {
    switch (await _gateway.manifest(conversionId)) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final manifest):
        var latest = manifest;
        return _download(conversionId, manifest, onProgress, cancel, () async {
          final fresh = await _gateway.manifest(conversionId);
          if (fresh case Ok(:final value)) latest = value;
          return latest;
        });
    }
  }

  Future<Result<void, Failure>> _download(
    String conversionId,
    Manifest first,
    void Function(DownloadProgress)? onProgress,
    Future<void>? cancel,
    Future<Manifest> Function() refresh,
  ) async {
    var manifest = first;
    if (!manifest.complete) return const Result.err(NotDownloadable());

    final stored = await _files.read(conversionId);
    // Livre régénéré depuis (empreintes différentes) : on repart de zéro.
    if (stored != null && !_sameFiles(stored.manifest, manifest)) {
      await _files.remove(conversionId);
    }
    final verified = {
      if (stored != null && _sameFiles(stored.manifest, manifest))
        ...stored.verified,
    };
    await _files.save(conversionId, manifest);

    final parts = [...manifest.parts]
      ..sort((a, b) => a.index.compareTo(b.index));
    final total = manifestBytes(manifest);
    var done = 0;
    for (final part in parts) {
      if (verified.contains(part.index)) done += partBytes(part);
    }
    void report(int extra) => onProgress?.call(
      DownloadProgress(
        partsDone: verified.length,
        partCount: parts.length,
        bytesDone: done + extra,
        bytesTotal: total,
      ),
    );
    report(0);

    var refreshed = false;
    for (final original in parts) {
      if (verified.contains(original.index)) continue;
      var received = 0;
      for (final kind in PartFile.values) {
        var attempts = 0;
        while (true) {
          final part = manifest.parts.firstWhere(
            (p) => p.index == original.index,
          );
          final file = kind == PartFile.audio ? part.audio : part.vtt;
          final url = file?.url;
          if (file == null || url == null) {
            return const Result.err(NotDownloadable());
          }
          final path = await _files.pathOf(conversionId, part.index, kind);
          final result = await _gateway.download(
            url,
            path,
            onBytes: (bytes) => report(received + bytes),
            cancel: cancel,
          );
          if (result case Err(:final error)) {
            await _files.deleteFile(path);
            // URL signées expirées : un nouveau manifeste, une seule fois.
            if (error.code == 'FORBIDDEN' && !refreshed) {
              refreshed = true;
              manifest = await refresh();
              continue;
            }
            return Result.err(error);
          }
          if (await _files.matches(path, file.sha256)) {
            received += file.bytes;
            break;
          }
          await _files.deleteFile(path);
          if (++attempts >= 2) return const Result.err(CorruptDownload());
        }
      }
      await _files.markVerified(conversionId, original.index);
      verified.add(original.index);
      done += partBytes(original);
      report(0);
    }
    await _files.markComplete(conversionId);
    return const Result.ok(null);
  }

  /// Mêmes parties, mêmes empreintes.
  static bool _sameFiles(Manifest a, Manifest b) {
    if (a.parts.length != b.parts.length) return false;
    final sums = {
      for (final p in a.parts) p.index: (p.audio?.sha256, p.vtt?.sha256),
    };
    return b.parts.every(
      (p) => sums[p.index] == (p.audio?.sha256, p.vtt?.sha256),
    );
  }
}
