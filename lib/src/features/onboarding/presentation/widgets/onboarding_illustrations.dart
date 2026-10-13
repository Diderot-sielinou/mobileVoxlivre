import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';

/// Cadre commun des illustrations : carte sombre éclairée par l'« Aube »
/// (le dégradé signature, adouci pour laisser l'action principale en avant).
/// Décoratif : le titre de la page porte le sens, les lecteurs d'écran
/// ignorent l'illustration.
class IllustrationPanel extends StatelessWidget {
  const IllustrationPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VoxRadius.sheet),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(VoxRadius.sheet),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Opacity(
                opacity: 0.35,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: VoxGradients.aube),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(VoxSpacing.lg),
                child: Center(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page 1 : un PDF devient une voix.
class ImportIllustration extends StatelessWidget {
  const ImportIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 104,
          padding: const EdgeInsets.all(VoxSpacing.md),
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(VoxRadius.chip),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                color: colors.accent,
                size: 32,
              ),
              const SizedBox(height: VoxSpacing.md),
              for (final width in [64.0, 72.0, 48.0, 60.0]) ...[
                _Line(width: width, color: colors.border),
                const SizedBox(height: VoxSpacing.sm),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VoxSpacing.md),
          child: Icon(Icons.arrow_forward, color: colors.text, size: 28),
        ),
        const _Wave(),
      ],
    );
  }
}

/// Page 2 : chaque mot s'illumine au rythme de la voix. Le surlignage avance
/// d'un mot toutes les 700 ms (150 ms de transition) tant que la page est
/// visible ([active]) ; « réduire les animations » : un mot reste allumé.
class ListenIllustration extends StatefulWidget {
  const ListenIllustration({required this.active, super.key});

  final bool active;

  @override
  State<ListenIllustration> createState() => _ListenIllustrationState();
}

class _ListenIllustrationState extends State<ListenIllustration> {
  static const _words = [
    'Dans',
    'le',
    'silence',
    'lumineux',
    'du',
    'soir,',
    'les',
    'pensées',
    'deviennent',
    'clarté.',
  ];

  Timer? _timer;
  int _current = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ListenIllustration old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final animate = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (animate && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        setState(() => _current = (_current + 1) % _words.length);
      });
    } else if (!animate) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final card = BoxDecoration(
      color: colors.elevated,
      borderRadius: BorderRadius.circular(VoxRadius.chip),
      border: Border.all(color: colors.border),
    );
    const tabular = TextStyle(fontFeatures: VoxTypography.tabularFigures);

    // Réduit au besoin sur les petits écrans plutôt que de déborder.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Pill(
              icon: Icons.graphic_eq,
              label: 'Synthèse vocale synchronisée',
            ),
            const SizedBox(height: VoxSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // La page du livre…
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(
                        VoxSpacing.sm + VoxSpacing.xs,
                      ),
                      decoration: card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final width in [
                            52.0,
                            92.0,
                            76.0,
                            92.0,
                            60.0,
                          ]) ...[
                            _Line(width: width, color: colors.border),
                            const SizedBox(height: VoxSpacing.sm),
                          ],
                          const Spacer(),
                          Text('p. 142', style: text.labelSmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: VoxSpacing.sm),
                  // … et le même passage, lu à voix haute.
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(
                        VoxSpacing.sm + VoxSpacing.xs,
                      ),
                      decoration: card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                size: 16,
                                color: colors.accent,
                              ),
                              const SizedBox(width: VoxSpacing.xs),
                              Flexible(
                                child: Text(
                                  '02:18 / 05:40',
                                  overflow: TextOverflow.ellipsis,
                                  style: text.labelSmall
                                      ?.merge(tabular)
                                      .copyWith(
                                        color: colors.accent,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VoxSpacing.sm),
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: [
                              for (var i = 0; i < _words.length; i++)
                                _Word(
                                  word: _words[i],
                                  current: i == _current,
                                  read: i < _current,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VoxSpacing.sm),
            // Barre de lecture.
            Container(
              padding: const EdgeInsets.all(VoxSpacing.sm),
              decoration: card.copyWith(color: colors.background),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pause, size: 20, color: colors.onAccent),
                  ),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vitesse 1,15×',
                      style: text.labelMedium?.merge(tabular),
                    ),
                  ),
                  for (final lit in [true, true, false])
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: VoxSpacing.xs),
                      decoration: BoxDecoration(
                        color: lit ? colors.accent : colors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un mot du passage : surligné (en cours), lu, ou à venir.
class _Word extends StatelessWidget {
  const _Word({required this.word, required this.current, required this.read});

  final String word;
  final bool current;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return AnimatedContainer(
      duration: VoxMotion.wordHighlight,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: VoxSpacing.xs,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: current
            ? colors.wordHighlight
            : colors.wordHighlight.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        word,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: current
              ? colors.onWordHighlight
              : read
              ? colors.text
              : colors.textSecondary,
        ),
      ),
    );
  }
}

/// Étiquette arrondie : icône ambre + texte.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoxSpacing.sm + VoxSpacing.xs,
        vertical: VoxSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(VoxRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: VoxSpacing.sm),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 3 : le livre est téléchargé, il s'écoute sans réseau.
class OfflineIllustration extends StatelessWidget {
  const OfflineIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.elevated,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.3),
                blurRadius: 40,
              ),
            ],
          ),
          child: Icon(Icons.headphones, size: 52, color: colors.accent),
        ),
        const SizedBox(height: VoxSpacing.lg),
        Wrap(
          spacing: VoxSpacing.sm,
          runSpacing: VoxSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _Badge(
              icon: Icons.download_done,
              label: 'Téléchargé',
              color: colors.success,
            ),
            _Badge(
              icon: Icons.wifi_off,
              label: 'Sans réseau',
              color: colors.text,
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoxSpacing.sm + VoxSpacing.xs,
        vertical: VoxSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(VoxRadius.chip),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: VoxSpacing.xs + 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 6,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

/// Cinq barres d'onde sonore, dégradé « Braise ».
class _Wave extends StatelessWidget {
  const _Wave();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final height in [28.0, 52.0, 76.0, 44.0, 60.0]) ...[
          Container(
            width: 10,
            height: height,
            decoration: BoxDecoration(
              // « Braise », vertical : du bas vers le haut.
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: VoxGradients.braise.colors,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}
