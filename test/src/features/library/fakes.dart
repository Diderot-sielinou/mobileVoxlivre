import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/domain/library_repository.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';

import '../auth/fakes.dart';

/// Bibliothèque en mémoire : [remote] est ce que « le réseau » renverra au
/// prochain rafraîchissement, [failure] le fait échouer.
final class FakeLibraryRepository implements LibraryRepository {
  FakeLibraryRepository({this.remote = const [], LibrarySnapshot? cached})
    : _snapshot = cached ?? LibrarySnapshot.empty;

  List<LibraryItem> remote;
  String? failure;
  DateTime now = DateTime.utc(2026, 10, 13, 12);
  int refreshes = 0;
  int clears = 0;

  /// Retient la réponse du « réseau » tant qu'il n'est pas complété.
  Completer<void>? gate;

  LibrarySnapshot _snapshot;
  final _changes = StreamController<LibrarySnapshot>.broadcast();

  LibrarySnapshot get snapshot => _snapshot;

  @override
  Stream<LibrarySnapshot> watch() {
    // Abonné tout de suite aux changements (un `async*` s'abonnerait trop
    // tard et manquerait le premier rafraîchissement).
    late final StreamSubscription<LibrarySnapshot> changes;
    final controller = StreamController<LibrarySnapshot>(
      onCancel: () => changes.cancel(),
    )..add(_snapshot);
    changes = _changes.stream.listen(controller.add);
    return controller.stream;
  }

  @override
  Future<DateTime?> lastRefresh() async => _snapshot.refreshedAt;

  @override
  Future<Result<void, Failure>> refresh() async {
    refreshes++;
    await gate?.future;
    if (failure case final code?) return Result.err(FakeFailure(code));
    _set(LibrarySnapshot(items: remote, refreshedAt: now));
    return const Result.ok(null);
  }

  @override
  Future<void> clear() async {
    clears++;
    _set(LibrarySnapshot.empty);
  }

  void _set(LibrarySnapshot next) {
    _snapshot = next;
    _changes.add(next);
  }
}

/// Livre de test.
LibraryItem book(
  String id, {
  String? title,
  LibraryStatus status = LibraryStatus.ready,
  int? progressPercent,
  Duration playable = const Duration(minutes: 74),
  DateTime? listenedAt,
  int partsReady = 3,
  int? partCount = 3,
  String? extractionError,
  String? failureReason,
  int? pageCount = 84,
}) => LibraryItem(
  documentId: id,
  title: title ?? 'Livre $id',
  status: status,
  importedAt: DateTime.utc(2026, 10, 2),
  pageCount: pageCount,
  extractionError: extractionError,
  progressPercent: progressPercent,
  conversion: status == LibraryStatus.notConverted
      ? null
      : ConversionSummary(
          id: 'c-$id',
          status: 'ready',
          partsReady: partsReady,
          partCount: partCount,
          playable: playable,
          failureReason: failureReason,
        ),
  position: listenedAt == null
      ? null
      : ReadingPoint(
          wordIndex: 10,
          audio: Duration.zero,
          recordedAt: listenedAt,
        ),
);

/// Fiches en mémoire : [remote] est ce que « le réseau » renverra au
/// prochain rafraîchissement ; [failure] fait échouer le prochain appel
/// (rafraîchir, renommer ou supprimer).
final class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({Map<String, DocumentSheet>? remote, this.cached})
    : remote = remote ?? {};

  Map<String, DocumentSheet> remote;
  DocumentSheet? cached;
  String? failure;
  int refreshes = 0;
  final renamed = <String>[];
  final deleted = <String>[];

  /// Retient la réponse du « réseau » tant qu'il n'est pas complété.
  Completer<void>? gate;

  final _changes = StreamController<DocumentSheet?>.broadcast();

  @override
  Stream<DocumentSheet?> watch(String documentId) {
    late final StreamSubscription<DocumentSheet?> changes;
    final controller = StreamController<DocumentSheet?>(
      onCancel: () => changes.cancel(),
    )..add(cached?.id == documentId ? cached : null);
    changes = _changes.stream
        .where((s) => s == null || s.id == documentId)
        .listen(controller.add);
    return controller.stream;
  }

  @override
  Future<Result<void, Failure>> refresh(String documentId) async {
    refreshes++;
    await gate?.future;
    if (failure case final code?) return Result.err(FakeFailure(code));
    if (remote[documentId] case final sheet?) _set(sheet);
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> rename(String documentId, String title) async {
    await gate?.future;
    if (failure case final code?) return Result.err(FakeFailure(code));
    renamed.add(title);
    if (cached case final sheet?) _set(sheet.copyWith(title: title));
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> delete(String documentId) async {
    await gate?.future;
    if (failure case final code?) return Result.err(FakeFailure(code));
    deleted.add(documentId);
    cached = null;
    _changes.add(null);
    return const Result.ok(null);
  }

  void _set(DocumentSheet sheet) {
    cached = sheet;
    _changes.add(sheet);
  }
}

/// Fiche de test : texte prêt, 120 pages.
DocumentSheet sheet(
  String id, {
  String? title,
  DocumentStage stage = DocumentStage.textReady,
  ExtractionMethod? method = ExtractionMethod.native,
  bool reviewRequired = false,
  DateTime? reviewedAt,
  ({int done, int total})? ocrProgress,
  String? extractionError,
  List<OutlineEntry> outline = const [],
}) => DocumentSheet(
  id: id,
  title: title ?? 'Livre $id',
  stage: stage,
  pageCount: 120,
  charCount: 214300,
  method: method,
  reviewRequired: reviewRequired,
  reviewedAt: reviewedAt,
  ocrProgress: ocrProgress,
  extractionError: extractionError,
  outline: outline,
);
