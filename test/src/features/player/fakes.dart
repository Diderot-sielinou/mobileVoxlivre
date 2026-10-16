import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

import '../auth/fakes.dart';

/// WebVTT d'une partie : un mot par seconde, à partir de l'index [first].
String vttOf(List<String> words, {int first = 0}) {
  String t(int s) => '00:00:${s.toString().padLeft(2, '0')}.000';
  return [
    'WEBVTT',
    '',
    for (var i = 0; i < words.length; i++) ...[
      '${first + i}',
      '${t(i)} --> ${t(i + 1)}',
      words[i],
      '',
    ],
  ].join('\n');
}

ManifestPart part(
  int index, {
  required int startMs,
  required int firstWord,
  bool ready = true,
  int durationMs = 4000,
  List<({int page, int wordIndex})> pageStarts = const [],
}) => ManifestPart(
  index: index,
  ready: ready,
  firstWordIndex: firstWord,
  startMs: ready ? startMs : null,
  durationMs: ready ? durationMs : null,
  pageStarts: pageStarts,
  audio: ready
      ? ManifestFile(
          url: Uri.parse('https://s.test/p$index.mp3'),
          bytes: 1,
          sha256: 'a',
        )
      : null,
  vtt: ready
      ? ManifestFile(
          url: Uri.parse('https://s.test/p$index.vtt'),
          bytes: 1,
          sha256: 'b',
        )
      : null,
);

/// Deux parties de 4 mots (une seconde chacun), pages 1 et 2.
Manifest testManifest({
  bool firstReady = true,
  bool secondReady = true,
  DateTime? expiresAt,
}) => Manifest(
  conversionId: 'c-1',
  documentId: 'd-1',
  complete: secondReady,
  partCount: 2,
  urlsExpireAt: expiresAt ?? DateTime.utc(2030),
  durationMs: secondReady ? 8000 : null,
  parts: [
    part(
      0,
      startMs: 0,
      firstWord: 0,
      ready: firstReady,
      pageStarts: [(page: 1, wordIndex: 0)],
    ),
    part(
      1,
      startMs: 4000,
      firstWord: 4,
      ready: secondReady,
      pageStarts: [(page: 2, wordIndex: 4)],
    ),
  ],
);

const vtts = {
  'https://s.test/p0.vtt': ['Le', 'droit', 'civil.', 'Il'],
  'https://s.test/p1.vtt': ['règle', 'les', 'contrats.', 'Fin'],
};

/// Backend du lecteur en mémoire.
final class FakePlayerGateway implements PlayerGateway {
  FakePlayerGateway({Manifest? manifest, this.remote})
    : current = manifest ?? testManifest();

  Manifest current;
  ReadingPosition? remote;
  String? manifestCode;
  String? vttCode;
  String? positionCode;
  final saved = <ReadingPosition>[];
  int manifests = 0;

  @override
  Future<Result<Manifest, Failure>> manifest(String conversionId) async {
    manifests++;
    if (manifestCode case final code?) return Result.err(FakeFailure(code));
    return Result.ok(current);
  }

  @override
  Future<Result<String, Failure>> vtt(Uri url) async {
    if (vttCode case final code?) return Result.err(FakeFailure(code));
    final words = vtts[url.toString()]!;
    final first = url.toString().endsWith('p1.vtt') ? 4 : 0;
    return Result.ok(vttOf(words, first: first));
  }

  @override
  Future<Result<ReadingPosition?, Failure>> position(
    String conversionId,
  ) async {
    if (positionCode case final code?) return Result.err(FakeFailure(code));
    return Result.ok(remote);
  }

  @override
  Future<Result<void, Failure>> savePosition(
    String conversionId,
    ReadingPosition position,
  ) async {
    saved.add(position);
    return const Result.ok(null);
  }
}

final class MemoryPositionStore implements PositionStore {
  MemoryPositionStore([this.position]);

  ReadingPosition? position;
  int clears = 0;

  @override
  Future<ReadingPosition?> read(String conversionId) async => position;

  @override
  Future<void> write(String conversionId, ReadingPosition p) async =>
      position = p;

  @override
  Future<void> clear() async {
    clears++;
    position = null;
  }
}

/// Moteur audio piloté à la main : [emit] simule la lecture.
final class FakeAudioEngine implements AudioEngine {
  final loads = <({List<AudioPart> parts, int startMs})>[];
  final appended = <AudioPart>[];
  final seeks = <int>[];
  double speed = 1;
  bool disposed = false;
  final _positions = StreamController<int>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _completed = StreamController<void>.broadcast();

  void emit(int ms) => _positions.add(ms);

  /// Fin du dernier fichier : comme `just_audio`, reste « en lecture ».
  void finish() => _completed.add(null);

  @override
  Future<void> load(
    List<AudioPart> parts, {
    required int startMs,
    required String title,
  }) async => loads.add((parts: parts, startMs: startMs));

  @override
  Future<void> append(List<AudioPart> parts) async => appended.addAll(parts);

  @override
  Future<void> play() async => _playing.add(true);

  @override
  Future<void> pause() async => _playing.add(false);

  @override
  Future<void> seek(int ms) async => seeks.add(ms);

  @override
  Future<void> setSpeed(double value) async => speed = value;

  @override
  Stream<int> get positions => _positions.stream;

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Future<void> dispose() async => disposed = true;
}
