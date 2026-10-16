import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/player/presentation/bookmark_sheets.dart';
import 'package:voxlivre/src/features/player/presentation/player_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Durées proposées (maquette « Minuterie de sommeil »).
const List<({int minutes, String hint})> sleepPresets = [
  (minutes: 15, hint: 'Courte sieste'),
  (minutes: 30, hint: 'Recommandé'),
  (minutes: 45, hint: 'Repos'),
  (minutes: 60, hint: 'Nuit calme'),
];

/// Le son baisse sur les 30 dernières secondes.
const sleepFade = Duration(seconds: 30);

/// État de la minuterie.
@immutable
final class SleepTimerState {
  const SleepTimerState({
    this.remaining,
    this.total,
    this.endOfPage = false,
    this.fade = true,
  });

  /// Temps d'écoute avant l'arrêt ; `null` : pas de minuterie.
  final Duration? remaining;
  final Duration? total;

  /// Arrêt à la fin de la page en cours.
  final bool endOfPage;

  /// Fondu du son à la fin.
  final bool fade;

  bool get active => remaining != null;

  SleepTimerState copyWith({Duration? remaining, bool? fade}) =>
      SleepTimerState(
        remaining: remaining ?? this.remaining,
        total: total,
        endOfPage: endOfPage,
        fade: fade ?? this.fade,
      );
}

/// Minuterie de sommeil d'un livre ouvert : le temps ne compte que pendant
/// l'écoute ; à zéro, le lecteur se met en pause (position enregistrée).
final class SleepTimerController extends Notifier<SleepTimerState> {
  SleepTimerController(this.conversionId);

  final String conversionId;
  Timer? _tick;
  Timer? _last;

  /// Fin de page visée (instant audio), en mode « fin de la page ».
  int? _stopAtMs;

  static const _step = Duration(seconds: 1);

  @override
  SleepTimerState build() {
    ref.onDispose(_stopTimers);
    return const SleepTimerState();
  }

  PlayerController get _player =>
      ref.read(playerControllerProvider(conversionId).notifier);

  PlayerViewState get _view => ref.read(playerControllerProvider(conversionId));

  /// Arrêt après [duration] d'écoute.
  void start(Duration duration) {
    _stopAtMs = null;
    _begin(duration, endOfPage: false);
  }

  /// Arrêt à la fin de la page en cours.
  void startEndOfPage() {
    final stopAt = pageEndOf(_view);
    if (stopAt == null) return;
    _stopAtMs = stopAt;
    _begin(_untilEndOfPage(stopAt), endOfPage: true);
  }

  void cancel() {
    _stopTimers();
    state = SleepTimerState(fade: state.fade);
    unawaited(_player.setVolume(1));
  }

  void setFade({required bool fade}) {
    state = state.copyWith(fade: fade);
    if (!fade) unawaited(_player.setVolume(1));
  }

  /// Temps d'écoute jusqu'à la fin de page [stopAt], à la vitesse choisie.
  Duration _untilEndOfPage(int stopAt) {
    final view = _view;
    final ms = (stopAt - view.positionMs) / view.speed;
    return Duration(milliseconds: math.max(0, ms.round()));
  }

  void _begin(Duration duration, {required bool endOfPage}) {
    _stopTimers();
    state = SleepTimerState(
      remaining: duration,
      total: duration,
      endOfPage: endOfPage,
      fade: state.fade,
    );
    unawaited(_player.setVolume(1));
    _tick = Timer.periodic(_step, (_) => _onTick());
  }

  void _onTick() {
    // En pause, la minuterie attend.
    if (!_view.playing || _last != null) return;
    final left = switch (_stopAtMs) {
      final stopAt? => _untilEndOfPage(stopAt),
      null => state.remaining! - _step,
    };
    if (left <= _step) {
      // Dernière seconde : arrêt à l'instant près.
      _last = Timer(left, () => unawaited(_finish()));
    }
    state = state.copyWith(
      remaining: left < Duration.zero ? Duration.zero : left,
    );
    if (state.fade && left < sleepFade) {
      unawaited(
        _player.setVolume(left.inMilliseconds / sleepFade.inMilliseconds),
      );
    }
  }

  Future<void> _finish() async {
    _stopTimers();
    await _player.pause();
    await _player.setVolume(1);
    state = SleepTimerState(fade: state.fade);
  }

  void _stopTimers() {
    _tick?.cancel();
    _last?.cancel();
    _tick = null;
    _last = null;
  }
}

/// Instant de fin de la page en cours, `null` sans texte.
int? pageEndOf(PlayerViewState view) {
  final text = view.text;
  if (text == null || text.isEmpty) return null;
  return text.pageEndMs(view.wordPosition);
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final sleepTimerProvider = NotifierProvider.autoDispose
    .family<SleepTimerController, SleepTimerState, String>(
      SleepTimerController.new,
    );

/// « 27:33 » ou « 1:05:00 ».
String sleepClock(Duration d) => VoxFormat.clock(d.inMilliseconds + 999);

/// Annonce : « arrêt dans 27 min » (« moins d'une minute » à la fin).
String sleepSpoken(Duration d) {
  final minutes = (d.inSeconds / 60).ceil();
  return minutes <= 1
      ? 'arrêt dans moins d’une minute'
      : 'arrêt dans $minutes min';
}

/// Bouton de la barre du lecteur : lune, ou le décompte quand la
/// minuterie tourne.
class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({required this.conversionId, super.key});

  final String conversionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider(conversionId));
    final remaining = timer.remaining;
    void open() => unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        sheetAnimationStyle: sheetAnimation(context),
        builder: (_) => SleepTimerSheet(conversionId: conversionId),
      ),
    );
    if (remaining == null) {
      return IconButton(
        tooltip: 'Minuterie de sommeil',
        onPressed: open,
        icon: const Icon(Icons.bedtime_outlined),
      );
    }
    return Semantics(
      button: true,
      label: 'Minuterie de sommeil, ${sleepSpoken(remaining)}',
      excludeSemantics: true,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            VoxSizes.minTouchTarget,
            VoxSizes.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: VoxSpacing.xs),
        ),
        onPressed: open,
        icon: const Icon(Icons.bedtime, size: 18),
        label: Text(
          sleepClock(remaining),
          style: const TextStyle(
            fontFeatures: VoxTypography.tabularFigures,
          ),
        ),
      ),
    );
  }
}

/// Feuille « Minuterie de sommeil ».
class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({required this.conversionId, super.key});

  final String conversionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider(conversionId));
    final controller = ref.read(sleepTimerProvider(conversionId).notifier);
    final view = ref.watch(playerControllerProvider(conversionId));
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final remaining = timer.remaining;
    final pageEnd = pageEndOf(view);
    final pageLeft = pageEnd == null
        ? null
        : Duration(
            milliseconds: math.max(
              0,
              ((pageEnd - view.positionMs) / view.speed).round(),
            ),
          );

    void choose(VoidCallback start) {
      start();
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          0,
          VoxSpacing.screenMargin,
          VoxSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: colors.accent),
                const SizedBox(width: VoxSpacing.sm),
                Expanded(
                  child: Text('Minuterie de sommeil', style: text.titleLarge),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: VoxSpacing.md),
              Container(
                padding: const EdgeInsets.all(VoxSpacing.md),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(VoxRadius.card),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timer.endOfPage
                          ? 'En cours · fin de la page'
                          : 'En cours',
                      style: text.labelLarge?.copyWith(color: colors.accent),
                    ),
                    const SizedBox(height: VoxSpacing.xs),
                    Semantics(
                      label: sleepSpoken(remaining),
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Arrêt dans ',
                              style: text.bodyLarge,
                            ),
                            TextSpan(
                              text: sleepClock(remaining),
                              style: text.headlineMedium?.copyWith(
                                color: colors.accent,
                                fontFeatures: VoxTypography.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (timer.total case final total?
                        when total > Duration.zero) ...[
                      const SizedBox(height: VoxSpacing.sm),
                      ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value:
                              remaining.inMilliseconds / total.inMilliseconds,
                          minHeight: 6,
                          color: colors.accent,
                          backgroundColor: colors.border,
                        ),
                      ),
                    ],
                    const SizedBox(height: VoxSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: controller.cancel,
                        icon: const Icon(Icons.timer_off_outlined),
                        label: const Text('Annuler la minuterie'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VoxSpacing.lg),
            Text('Durées', style: text.titleSmall),
            const SizedBox(height: VoxSpacing.sm),
            // Deux par rangée, hauteur libre (texte agrandi).
            for (var i = 0; i < sleepPresets.length; i += 2) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final preset in sleepPresets.skip(i).take(2)) ...[
                      if (preset != sleepPresets[i])
                        const SizedBox(width: VoxSpacing.sm),
                      Expanded(
                        child: _Choice(
                          title: preset.minutes == 60
                              ? '1 h'
                              : '${preset.minutes} min',
                          hint: preset.hint,
                          onTap: () => choose(
                            () => controller.start(
                              Duration(minutes: preset.minutes),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: VoxSpacing.sm),
            ],
            if (pageLeft != null) ...[
              _Choice(
                icon: Icons.auto_stories_outlined,
                title: 'Fin de la page',
                hint: '${sleepClock(pageLeft)} restantes',
                onTap: () => choose(controller.startEndOfPage),
              ),
            ],
            const SizedBox(height: VoxSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: timer.fade,
              onChanged: (fade) => controller.setFade(fade: fade),
              title: const Text('Fondu du son à la fin'),
              subtitle: const Text(
                'Le volume baisse doucement pendant les 30 dernières '
                'secondes.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.title,
    required this.hint,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String hint;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(VoxRadius.chip);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: VoxSizes.minTouchTarget + VoxSpacing.md,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VoxSpacing.md,
              vertical: VoxSpacing.sm,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.accent),
                  const SizedBox(width: VoxSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: icon == null
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      Text(
                        hint,
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
