import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Vitesses proposées (maquette « Vitesse de lecture »).
const playerSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// Rythmes du lecteur.
const positionSaveEvery = Duration(seconds: 5);
const manifestRefreshEvery = Duration(seconds: 30);

/// Relire le manifeste avant que ses URL signées n'expirent.
const urlRenewBefore = Duration(minutes: 5);

/// État de l'écran du lecteur.
@immutable
final class PlayerViewState {
  const PlayerViewState({
    this.loading = true,
    this.errorCode,
    this.text,
    this.wordPosition = -1,
    this.positionMs = 0,
    this.durationMs = 0,
    this.playing = false,
    this.speed = 1,
    this.complete = true,
    this.partsReady = 0,
    this.partCount = 0,
  });

  final bool loading;
  final String? errorCode;
  final BookText? text;

  /// Mot prononcé (position dans `text.words`), `-1` avant le premier.
  final int wordPosition;
  final int positionMs;
  final int durationMs;
  final bool playing;
  final double speed;

  /// Conversion finie ; sinon on écoute un aperçu.
  final bool complete;
  final int partsReady;
  final int partCount;

  PlayerViewState copyWith({
    bool? loading,
    String? errorCode,
    BookText? text,
    int? wordPosition,
    int? positionMs,
    int? durationMs,
    bool? playing,
    double? speed,
    bool? complete,
    int? partsReady,
    int? partCount,
  }) => PlayerViewState(
    loading: loading ?? this.loading,
    errorCode: errorCode ?? this.errorCode,
    text: text ?? this.text,
    wordPosition: wordPosition ?? this.wordPosition,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    playing: playing ?? this.playing,
    speed: speed ?? this.speed,
    complete: complete ?? this.complete,
    partsReady: partsReady ?? this.partsReady,
    partCount: partCount ?? this.partCount,
  );
}

/// Le lecteur d'une conversion (ADR-0010). Aucune règle métier ici : la
/// position vient des cas d'usage, le mot courant de `BookText`.
final class PlayerController extends Notifier<PlayerViewState> {
  PlayerController(this.conversionId);

  final String conversionId;

  late AudioEngine _engine;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _saveTimer;
  Timer? _refreshTimer;
  Manifest? _manifest;
  int _lastLoadedIndex = -1;
  String _title = '';

  /// Copie de la dernière position : `state` est illisible pendant la
  /// libération.
  ({int wordIndex, int audioMs})? _last;

  @override
  set state(PlayerViewState value) {
    super.state = value;
    _last = _positionOf(value);
  }

  @override
  PlayerViewState build() {
    _engine = ref.watch(audioEngineProvider);
    // Lus ici : `ref` est interdit pendant la libération.
    final save = ref.read(savePositionProvider);
    ref.onDispose(() {
      _saveTimer?.cancel();
      _refreshTimer?.cancel();
      for (final subscription in _subscriptions) {
        unawaited(subscription.cancel());
      }
      final position = _last;
      if (position != null) {
        unawaited(
          save(
            conversionId,
            wordIndex: position.wordIndex,
            audioMs: position.audioMs,
          ),
        );
      }
    });
    return const PlayerViewState();
  }

  /// Ouvre le livre et se place à la position de reprise (sans jouer).
  Future<void> open(String title) async {
    _title = title;
    state = const PlayerViewState();
    // Positions écrites sans réseau : elles partent maintenant (ADR-0011).
    unawaited(ref.read(flushPositionsProvider)());
    final result = await ref.read(openBookProvider)(conversionId);
    if (!ref.mounted) return;
    switch (result) {
      case Err(:final error):
        state = state.copyWith(loading: false, errorCode: error.code);
      case Ok(value: final session):
        _manifest = session.manifest;
        _lastLoadedIndex = session.parts.last.index;
        final startMs = session.resumeAt?.audioMs ?? 0;
        await _engine.load(session.parts, startMs: startMs, title: title);
        if (!ref.mounted) return;
        state = PlayerViewState(
          loading: false,
          text: session.text,
          wordPosition: session.text.positionAt(startMs),
          positionMs: startMs,
          durationMs: _durationOf(session.manifest, session.text),
          complete: session.manifest.complete,
          partsReady: session.parts.length,
          partCount: session.manifest.partCount,
        );
        _listen();
        _refreshTimer = Timer.periodic(manifestRefreshEvery, (_) {
          unawaited(refreshManifest());
        });
    }
  }

  void _listen() {
    _subscriptions
      ..add(
        _engine.positions.listen((raw) {
          final text = state.text;
          if (text == null) return;
          // La fin du fichier peut dépasser la durée annoncée de quelques ms.
          final ms = raw.clamp(0, state.durationMs);
          final word = text.positionAt(ms);
          // Un nouvel état seulement si le mot ou la seconde change.
          if (word != state.wordPosition ||
              ms ~/ 1000 != state.positionMs ~/ 1000) {
            state = state.copyWith(wordPosition: word, positionMs: ms);
          }
        }),
      )
      ..add(
        _engine.playingChanges.listen((playing) {
          if (playing == state.playing) return;
          state = state.copyWith(playing: playing);
          _saveTimer?.cancel();
          if (playing) {
            _saveTimer = Timer.periodic(positionSaveEvery, (_) {
              unawaited(savePosition());
            });
          } else {
            unawaited(savePosition());
          }
        }),
      )
      // Fin du livre : le moteur reste « en lecture » ; on le met en pause
      // (ce qui enregistre la position, une seule fois).
      ..add(
        _engine.completed.listen((_) {
          state = state.copyWith(positionMs: state.durationMs);
          unawaited(_engine.pause());
        }),
      );
  }

  /// Lecture ou pause ; en fin de livre, la lecture reprend du début.
  Future<void> toggle() async {
    if (state.playing) return _engine.pause();
    if (state.durationMs > 0 && state.positionMs >= state.durationMs) {
      await seekTo(0);
    }
    await _engine.play();
  }

  /// Avance ou recule de [delta] ms, dans les bornes du livre.
  Future<void> seekBy(int delta) => seekTo(state.positionMs + delta);

  Future<void> seekTo(int ms) async {
    final target = ms.clamp(0, state.durationMs);
    state = state.copyWith(
      positionMs: target,
      wordPosition: state.text?.positionAt(target),
    );
    await _engine.seek(target);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _engine.setSpeed(speed);
  }

  /// Enregistre la position (appareil puis serveur).
  Future<void> savePosition() async {
    final position = _last;
    if (position == null) return;
    await ref.read(savePositionProvider)(
      conversionId,
      wordIndex: position.wordIndex,
      audioMs: position.audioMs,
    );
  }

  static ({int wordIndex, int audioMs})? _positionOf(PlayerViewState s) {
    final text = s.text;
    if (text == null || text.isEmpty) return null;
    final word = s.wordPosition < 0 ? 0 : s.wordPosition;
    return (wordIndex: text.words[word].index, audioMs: s.positionMs);
  }

  /// Aperçu : ajoute les parties devenues prêtes ; renouvelle les URL
  /// avant leur expiration.
  Future<void> refreshManifest() async {
    final previous = _manifest;
    if (previous == null) return;
    final now = ref.read(clockProvider).now();
    final expiring = previous.urlsExpireAt.difference(now) < urlRenewBefore;
    if (previous.complete && !expiring) return;

    final fresh = await ref.read(playerGatewayProvider).manifest(conversionId);
    if (!ref.mounted) return;
    if (fresh case Ok(value: final manifest)) {
      _manifest = manifest;
      if (expiring) {
        await _reload(manifest);
      } else {
        await _appendNewParts(manifest);
      }
    }
  }

  Future<void> _appendNewParts(Manifest manifest) async {
    final loaded = await ref.read(loadPartsProvider)(
      manifest,
      fromIndex: _lastLoadedIndex + 1,
    );
    if (!ref.mounted) return;
    if (loaded case Ok(value: final parts) when parts.audio.isNotEmpty) {
      await _engine.append(parts.audio);
      _lastLoadedIndex = parts.audio.last.index;
      final text = state.text!;
      final combined = BookText(
        [...text.words, ...parts.words],
        [
          for (final part in manifest.parts) ...part.pageStarts,
        ],
      );
      state = state.copyWith(
        text: combined,
        durationMs: _durationOf(manifest, combined),
        complete: manifest.complete,
        partsReady: _lastLoadedIndex + 1,
      );
    } else {
      state = state.copyWith(complete: manifest.complete);
    }
  }

  /// URL renouvelées : on recharge toutes les parties à la même place.
  Future<void> _reload(Manifest manifest) async {
    final loaded = await ref.read(loadPartsProvider)(manifest);
    if (!ref.mounted) return;
    if (loaded case Ok(value: final parts)) {
      final wasPlaying = state.playing;
      await _engine.load(parts.audio, startMs: state.positionMs, title: _title);
      _lastLoadedIndex = parts.audio.last.index;
      if (wasPlaying) await _engine.play();
    }
  }

  static int _durationOf(Manifest manifest, BookText text) {
    if (manifest.durationMs case final total?) return total;
    final parts = manifest.playableParts;
    if (parts.isNotEmpty) {
      final last = parts.last;
      return last.startMs! + (last.durationMs ?? 0);
    }
    return text.words.lastOrNull?.endMs ?? 0;
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final playerControllerProvider = NotifierProvider.autoDispose
    .family<PlayerController, PlayerViewState, String>(PlayerController.new);
