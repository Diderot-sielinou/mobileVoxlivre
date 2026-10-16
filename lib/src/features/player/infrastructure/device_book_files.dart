import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/infrastructure/manifest_json.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';

/// [BookFiles] (ADR-0011) : fichiers dans `<dossier de l'app>/books/<id>/`,
/// manifeste et parties vérifiées dans `player.sqlite`.
final class DeviceBookFiles implements BookFiles {
  DeviceBookFiles(this._db, this._root);

  final PlayerDatabase _db;

  /// Dossier de l'app (privé, non sauvegardé dans la galerie).
  final Future<Directory> Function() _root;

  /// Les URL d'un livre téléchargé n'expirent pas.
  static final _never = DateTime.utc(9999);

  Future<Directory> _books() async =>
      Directory('${(await _root()).path}/books');

  Future<Directory> _dir(String conversionId) async =>
      Directory('${(await _books()).path}/$conversionId');

  @override
  Future<String> pathOf(String conversionId, int index, PartFile file) async {
    final dir = await _dir(conversionId);
    await dir.create(recursive: true);
    final extension = file == PartFile.audio ? 'mp3' : 'vtt';
    return '${dir.path}/part-$index.$extension';
  }

  @override
  Future<StoredBook?> read(String conversionId) async {
    final row = await (_db.select(
      _db.downloadedBooks,
    )..where((t) => t.conversionId.equals(conversionId))).getSingleOrNull();
    if (row == null) return null;
    final verified = {
      for (final part in await (_db.select(
        _db.verifiedParts,
      )..where((t) => t.conversionId.equals(conversionId))).get())
        part.partIndex,
    };
    final saved = manifestFromJson(
      jsonDecode(row.manifestJson) as Map<String, Object?>,
    );
    ManifestFile? local(ManifestFile? file, String path, {required bool ok}) =>
        file == null
        ? null
        : ManifestFile(
            url: ok ? Uri.file(path) : null,
            bytes: file.bytes,
            sha256: file.sha256,
          );
    final dir = (await _dir(conversionId)).path;
    return StoredBook(
      verified: verified,
      complete: row.complete,
      manifest: Manifest(
        conversionId: saved.conversionId,
        documentId: saved.documentId,
        complete: saved.complete,
        partCount: saved.partCount,
        durationMs: saved.durationMs,
        urlsExpireAt: _never,
        parts: [
          for (final p in saved.parts)
            ManifestPart(
              index: p.index,
              ready: p.ready,
              firstWordIndex: p.firstWordIndex,
              startMs: p.startMs,
              durationMs: p.durationMs,
              wordCount: p.wordCount,
              pageStarts: p.pageStarts,
              audio: local(
                p.audio,
                '$dir/part-${p.index}.mp3',
                ok: verified.contains(p.index),
              ),
              vtt: local(
                p.vtt,
                '$dir/part-${p.index}.vtt',
                ok: verified.contains(p.index),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Future<void> save(String conversionId, Manifest manifest) => _db
      .into(_db.downloadedBooks)
      .insertOnConflictUpdate(
        DownloadedBooksCompanion.insert(
          conversionId: conversionId,
          manifestJson: jsonEncode(manifestToJson(manifest)),
        ),
      );

  @override
  Future<bool> matches(String path, String sha256Hex) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == sha256Hex.toLowerCase();
  }

  @override
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  @override
  Future<String> readText(String path) => File(path).readAsString();

  @override
  Future<void> markVerified(String conversionId, int index) => _db
      .into(_db.verifiedParts)
      .insertOnConflictUpdate(
        VerifiedPartsCompanion.insert(
          conversionId: conversionId,
          partIndex: index,
        ),
      );

  @override
  Future<void> markComplete(String conversionId) =>
      (_db.update(_db.downloadedBooks)
            ..where((t) => t.conversionId.equals(conversionId)))
          .write(const DownloadedBooksCompanion(complete: Value(true)));

  @override
  Future<void> remove(String conversionId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.verifiedParts,
      )..where((t) => t.conversionId.equals(conversionId))).go();
      await (_db.delete(
        _db.downloadedBooks,
      )..where((t) => t.conversionId.equals(conversionId))).go();
    });
    final dir = await _dir(conversionId);
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.verifiedParts).go();
      await _db.delete(_db.downloadedBooks).go();
    });
    final books = await _books();
    if (books.existsSync()) await books.delete(recursive: true);
  }

  @override
  Stream<Set<String>> watchComplete() =>
      (_db.select(_db.downloadedBooks)..where((t) => t.complete)).watch().map(
        (rows) => {for (final row in rows) row.conversionId},
      );
}
