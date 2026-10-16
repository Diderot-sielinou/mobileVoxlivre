import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Durée de fermeture de l'anneau.
const finishedRing = Duration(milliseconds: 1200);

/// « Livre terminé ! » (maquette « Fin du livre ») : durée et pages du
/// livre, prochain livre, revenir au début, libérer la place de l'audio.
class BookFinished extends StatefulWidget {
  const BookFinished({
    required this.title,
    required this.durationMs,
    required this.pageCount,
    required this.onClose,
    required this.onRestart,
    this.onChooseNext,
    this.downloadedBytes,
    this.onRemoveDownload,
    super.key,
  });

  final String title;
  final int durationMs;
  final int pageCount;
  final VoidCallback onClose;
  final VoidCallback onRestart;

  /// Vers la bibliothèque.
  final VoidCallback? onChooseNext;

  /// Taille de l'audio sur le téléphone, s'il est téléchargé.
  final int? downloadedBytes;
  final VoidCallback? onRemoveDownload;

  @override
  State<BookFinished> createState() => _BookFinishedState();
}

class _BookFinishedState extends State<BookFinished> {
  @override
  void initState() {
    super.initState();
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: colors.background,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Fermer',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: VoxSpacing.screenMargin,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: VoxSpacing.md),
                    // L'anneau se ferme une fois (instantané si l'on
                    // demande moins d'animations).
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                      duration: reduceMotion ? Duration.zero : finishedRing,
                      curve: Curves.easeOut,
                      builder: (context, value, _) => SizedBox.square(
                        dimension: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                color: colors.accent,
                                backgroundColor: colors.border,
                              ),
                            ),
                            Opacity(
                              opacity: value,
                              child: Icon(
                                Icons.check_rounded,
                                size: 64,
                                color: colors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VoxSpacing.lg),
                    Semantics(
                      header: true,
                      liveRegion: true,
                      child: Text(
                        'Livre terminé !',
                        style: text.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: VoxSpacing.sm),
                    Text(
                      'Vous avez écouté « ${widget.title} » jusqu’au bout.',
                      style: text.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VoxSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            icon: Icons.headphones_outlined,
                            value: VoxFormat.listening(
                              Duration(milliseconds: widget.durationMs),
                            ),
                            label: 'd’écoute',
                          ),
                        ),
                        const SizedBox(width: VoxSpacing.sm),
                        Expanded(
                          child: _Stat(
                            icon: Icons.menu_book_outlined,
                            value: '${widget.pageCount}',
                            label: widget.pageCount > 1 ? 'pages' : 'page',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VoxSpacing.xl),
                    if (widget.onChooseNext != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: VoxPrimaryButton(
                          label: 'Choisir mon prochain livre',
                          icon: Icons.arrow_forward,
                          onPressed: widget.onChooseNext,
                        ),
                      ),
                      const SizedBox(height: VoxSpacing.sm),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onRestart,
                        icon: const Icon(Icons.replay),
                        label: const Text('Revenir au début'),
                      ),
                    ),
                    if (widget.downloadedBytes case final bytes?
                        when widget.onRemoveDownload != null) ...[
                      const SizedBox(height: VoxSpacing.md),
                      TextButton.icon(
                        onPressed: widget.onRemoveDownload,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Supprimer l’audio pour libérer '
                          '${VoxFormat.bytes(bytes)}',
                        ),
                      ),
                    ],
                    const SizedBox(height: VoxSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(VoxSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VoxRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: MergeSemantics(
        child: Column(
          children: [
            Icon(icon, color: colors.accent),
            const SizedBox(height: VoxSpacing.xs),
            Text(value, style: text.titleMedium, textAlign: TextAlign.center),
            Text(
              label,
              style: text.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
