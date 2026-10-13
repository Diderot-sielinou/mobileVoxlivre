import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/onboarding/onboarding_providers.dart';
import 'package:voxlivre/src/features/onboarding/presentation/widgets/onboarding_illustrations.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';

/// Une page de l'onboarding.
class _Slide {
  const _Slide(this.title, this.body, this.illustration);

  final String title;
  final String body;
  final Widget Function({required bool active}) illustration;
}

final _slides = [
  _Slide(
    'Importez vos PDF et cours',
    'Ajoutez un livre, un cours ou un polycopié en PDF. Voxlivre en extrait '
        'le texte, même d’un document scanné.',
    ({required active}) => const ImportIllustration(),
  ),
  _Slide(
    'Écoutez en suivant le texte',
    'Chaque mot s’illumine au rythme d’une voix naturelle : vous lisez et '
        'écoutez en même temps, sans fatigue.',
    ({required active}) => ListenIllustration(active: active),
  ),
  _Slide(
    'Hors ligne, partout',
    'Téléchargez un livre audio une fois, puis écoutez-le sans connexion : '
        'dans le taxi, au campus ou à la maison.',
    ({required active}) => const OfflineIllustration(),
  ),
];

/// Premier lancement : trois pages, puis la connexion (ADR-0005).
///
/// Animations (design system §2, n° 2) : illustrations en parallaxe légère
/// au glissement, points de page élastiques (300 ms). « Réduire les
/// animations » : ni parallaxe ni glissement animé, changement direct.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.onFinished, super.key});

  /// Appelé une fois l'onboarding retenu comme vu (vers la connexion).
  final void Function(BuildContext context) onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingStoreProvider).complete();
    if (mounted) widget.onFinished(context);
  }

  Future<void> _next() async {
    if (_isLast) return _finish();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(_index + 1);
    } else {
      await _pages.nextPage(
        duration: VoxMotion.page,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VoxSpacing.screenMargin,
                VoxSpacing.sm,
                VoxSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: Text(
                      'ÉTAPE ${_index + 1} SUR ${_slides.length}',
                      style: text.labelSmall?.copyWith(letterSpacing: 1.2),
                    ),
                  ),
                  if (!_isLast)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                      ),
                      child: const Text('Passer'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _SlideView(
                  slide: _slides[index],
                  index: index,
                  pages: _pages,
                  active: index == _index,
                  parallax: !reduceMotion,
                ),
              ),
            ),
            _Dots(
              count: _slides.length,
              current: _index,
              animate: !reduceMotion,
            ),
            Padding(
              padding: const EdgeInsets.all(VoxSpacing.screenMargin),
              child: VoxPrimaryButton(
                label: _isLast ? 'Commencer' : 'Continuer',
                icon: Icons.arrow_forward,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.index,
    required this.pages,
    required this.active,
    required this.parallax,
  });

  final _Slide slide;
  final int index;
  final PageController pages;
  final bool active;
  final bool parallax;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VoxSpacing.screenMargin),
      child: Column(
        children: [
          const SizedBox(height: VoxSpacing.md),
          Expanded(
            child: AnimatedBuilder(
              animation: pages,
              builder: (context, child) {
                // Parallaxe : l'illustration glisse moins vite que la page.
                final page = pages.hasClients && pages.position.haveDimensions
                    ? pages.page ?? index.toDouble()
                    : index.toDouble();
                final dx = parallax ? (index - page) * 48 : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: IllustrationPanel(
                child: slide.illustration(active: active),
              ),
            ),
          ),
          const SizedBox(height: VoxSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: VoxSpacing.sm),
          Text(
            slide.body,
            style: text.bodyLarge?.copyWith(color: context.vox.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VoxSpacing.lg),
        ],
      ),
    );
  }
}

/// Points de page : le point courant s'étire (« élastique »).
class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.current,
    required this.animate,
  });

  final int count;
  final int current;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Semantics(
      label: 'Page ${current + 1} sur $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: animate ? VoxMotion.page : Duration.zero,
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.symmetric(horizontal: VoxSpacing.xs),
                width: i == current ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == current ? colors.accent : colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
