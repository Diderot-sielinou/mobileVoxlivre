import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_logo.dart';

/// Splash animé du lancement (design system §2, n° 1) : le halo « Aube » se
/// lève, l'onde du logo monte, le nom apparaît (900 ms, easeOutCubic), puis
/// le splash s'efface (200 ms) sur l'app, déjà construite dessous.
///
/// Une seule fois par démarrage. « Réduire les animations » : pas de
/// splash, l'app s'affiche directement.
class SplashGate extends StatefulWidget {
  const SplashGate({required this.child, super.key});

  final Widget child;

  /// Durée de l'animation d'entrée.
  static const intro = Duration(milliseconds: 900);

  /// Temps de lecture du nom une fois l'animation finie.
  static const hold = Duration(milliseconds: 250);

  /// Effacement vers l'app.
  static const fade = Duration(milliseconds: 200);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  // Entrée puis maintien, dans une seule animation : rien n'attend hors
  // d'une animation (les tests la suivent image par image).
  late final AnimationController _intro;
  bool _started = false;
  bool _fading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: SplashGate.intro + SplashGate.hold,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
      return;
    }
    _intro.forward().then((_) {
      if (mounted) setState(() => _fading = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _fading ? 0 : 1,
            duration: SplashGate.fade,
            onEnd: () => setState(() => _done = true),
            child: _SplashView(animation: _intro),
          ),
        ),
      ],
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView({required this.animation});

  final Animation<double> animation;

  /// Part de l'entrée dans l'animation (le reste est le maintien).
  static final double _introShare =
      SplashGate.intro.inMilliseconds /
      (SplashGate.intro + SplashGate.hold).inMilliseconds;

  /// Portion [begin, end] de l'entrée, adoucie.
  Animation<double> _part(double begin, double end) => CurvedAnimation(
    parent: animation,
    curve: Interval(
      begin * _introShare,
      end * _introShare,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final glow = _part(0, 0.6);
    final wave = _part(0.15, 0.9);
    final words = _part(0.4, 1);
    final line = _part(0, 1);

    // Le splash couvre l'app : il absorbe les appuis et se présente seul aux
    // lecteurs d'écran.
    return Semantics(
      label: 'Voxlivre. Lisez. Écoutez. Vivez le livre.',
      container: true,
      child: ExcludeSemantics(
        child: AbsorbPointer(
          child: ColoredBox(
            color: colors.background,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Stack(
                children: [
                  // Halo « Aube » qui se lève derrière le logo.
                  Positioned.fill(
                    child: Opacity(
                      opacity: glow.value,
                      child: Transform.translate(
                        offset: Offset(0, 80 * (1 - glow.value)),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.25),
                              radius: 0.9,
                              colors: [
                                VoxGradients.aube.colors[1].withValues(
                                  alpha: 0.35,
                                ),
                                VoxGradients.aube.colors[2].withValues(
                                  alpha: 0.08,
                                ),
                                colors.background.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Toute la surface : sans `Positioned.fill`, la colonne prend
                  // la largeur de son plus large enfant et se colle à gauche
                  // (vu sur le téléphone).
                  Positioned.fill(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VoxSpacing.screenMargin,
                        ),
                        child: Column(
                          children: [
                            const Spacer(flex: 3),
                            Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.surface.withValues(alpha: 0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.accent.withValues(
                                      alpha: 0.25 * glow.value,
                                    ),
                                    blurRadius: 48,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: VoxLogo(size: 88, progress: wave.value),
                            ),
                            const SizedBox(height: VoxSpacing.lg),
                            Opacity(
                              opacity: words.value,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - words.value)),
                                child: Column(
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(text: 'Vox'),
                                          TextSpan(
                                            text: 'livre',
                                            style: TextStyle(
                                              color: colors.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: text.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: VoxSpacing.sm),
                                    Text(
                                      'Lisez. Écoutez. Vivez le livre.',
                                      style: text.bodyLarge?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: VoxSpacing.md),
                                    const _Chip(
                                      icon: Icons.graphic_eq,
                                      label: 'Texte et voix synchronisés',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(flex: 4),
                            // Fine ligne « Braise » qui se remplit pendant
                            // l'animation (pas un faux pourcentage).
                            SizedBox(
                              width: 176,
                              height: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: line.value,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: VoxGradients.braise,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: VoxSpacing.md),
                            Text(
                              'Fait pour les apprenants',
                              style: text.bodySmall,
                            ),
                            const SizedBox(height: VoxSpacing.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VoxSpacing.sm + VoxSpacing.xs,
        vertical: VoxSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VoxRadius.chip),
        border: Border.all(color: colors.border),
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
