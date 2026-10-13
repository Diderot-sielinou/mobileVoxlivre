import 'package:flutter/material.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// Squelettes aux dimensions des cartes (design system §2, n° 13) : jamais
/// un indicateur seul. Pulsation de 1,2 s ; « réduire les animations » :
/// fixes.
class LibrarySkeleton extends StatefulWidget {
  const LibrarySkeleton({this.count = 3, super.key});

  final int count;

  @override
  State<LibrarySkeleton> createState() => _LibrarySkeletonState();
}

class _LibrarySkeletonState extends State<LibrarySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      label: 'Chargement de la bibliothèque',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
          child: Column(
            children: [
              for (var i = 0; i < widget.count; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        VoxSpacing.sm + VoxSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          block(56, 72),
                          const SizedBox(width: VoxSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                block(180, 14),
                                const SizedBox(height: VoxSpacing.sm),
                                block(96, 12),
                                const SizedBox(height: VoxSpacing.sm),
                                block(140, 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
