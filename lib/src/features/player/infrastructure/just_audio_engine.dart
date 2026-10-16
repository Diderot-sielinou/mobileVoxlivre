import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// [AudioEngine] sur `just_audio` (+ `just_audio_background` : notification,
/// écran verrouillé), ADR-0010. Les parties forment une liste enchaînée ;
/// l'instant absolu = début de la partie courante + instant dans la partie.
final class JustAudioEngine implements AudioEngine {
  JustAudioEngine([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  final _parts = <AudioPart>[];
  String _title = '';

  int _absolute(int? index, Duration position) {
    if (index == null || index >= _parts.length) return 0;
    return _parts[index].startMs + position.inMilliseconds;
  }

  AudioSource _source(AudioPart part) => AudioSource.uri(
    part.url,
    tag: MediaItem(
      id: 'part-${part.index}',
      title: _title,
      album: 'Voxlivre',
    ),
  );

  @override
  Future<void> load(
    List<AudioPart> parts, {
    required int startMs,
    required String title,
  }) async {
    _title = title;
    _parts
      ..clear()
      ..addAll(parts);
    final (index, offset) = _locate(startMs);
    await _player.setAudioSources(
      [for (final part in parts) _source(part)],
      initialIndex: index,
      initialPosition: Duration(milliseconds: offset),
    );
  }

  @override
  Future<void> append(List<AudioPart> parts) async {
    final fresh = [
      for (final part in parts)
        if (_parts.every((p) => p.index != part.index)) part,
    ];
    if (fresh.isEmpty) return;
    _parts.addAll(fresh);
    await _player.addAudioSources([for (final part in fresh) _source(part)]);
  }

  /// Partie qui contient [ms], et l'instant dans cette partie.
  (int, int) _locate(int ms) {
    var index = 0;
    for (var i = 0; i < _parts.length; i++) {
      if (_parts[i].startMs <= ms) index = i;
    }
    if (_parts.isEmpty) return (0, 0);
    return (index, (ms - _parts[index].startMs).clamp(0, 1 << 31));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(int ms) {
    final (index, offset) = _locate(ms);
    return _player.seek(Duration(milliseconds: offset), index: index);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1));

  @override
  Stream<int> get positions => _player
      .createPositionStream(
        // Assez fin pour suivre un mot (≈ 300 ms à vitesse 2×).
        minPeriod: const Duration(milliseconds: 50),
        maxPeriod: const Duration(milliseconds: 100),
      )
      .map((position) => _absolute(_player.currentIndex, position));

  @override
  Stream<bool> get playingChanges => _player.playingStream;

  @override
  Stream<void> get completed => _player.processingStateStream
      .where((state) => state == ProcessingState.completed)
      .map((_) {});

  @override
  Future<void> dispose() => _player.dispose();
}
