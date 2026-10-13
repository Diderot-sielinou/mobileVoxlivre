import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
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
