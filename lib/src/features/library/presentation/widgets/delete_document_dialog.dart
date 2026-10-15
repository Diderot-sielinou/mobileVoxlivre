import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_cover.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Suppression d'un document (maquette « Supprimer un document ») :
/// confirmation, puis suppression, ou « Suppression suspendue » si une
/// conversion est en cours (409). [onDelete] rend `null` si c'est fait,
/// sinon le code de l'échec. Rend `true` si le document a été supprimé.
Future<bool> showDeleteDocumentDialog(
  BuildContext context, {
  required String title,
  required int? pageCount,
  required ConversionSummary? conversion,
  required Future<String?> Function() onDelete,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(
        title: title,
        pageCount: pageCount,
        conversion: conversion,
        onDelete: onDelete,
      ),
    ) ??
    false;

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({
    required this.title,
    required this.pageCount,
    required this.conversion,
    required this.onDelete,
  });

  final String title;
  final int? pageCount;
  final ConversionSummary? conversion;
  final Future<String?> Function() onDelete;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  bool _busy = false;
  bool _blocked = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final code = await widget.onDelete();
    if (!mounted) return;
    if (code == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _blocked = code == 'DOCUMENT_DELETION_CONFLICT';
      _error = _blocked
          ? null
          : switch (code) {
              'NETWORK_UNAVAILABLE' ||
              'TIMEOUT' => 'Pas de connexion : rien n’a été supprimé.',
              _ => 'La suppression a échoué. Réessayez dans un instant.',
            };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final swap = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : VoxMotion.swap;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VoxRadius.sheet),
      ),
      backgroundColor: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.lg),
        child: AnimatedSwitcher(
          duration: swap,
          child: _blocked
              ? _Blocked(key: const ValueKey('blocked'), widget: widget)
              : Column(
                  key: const ValueKey('confirm'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconBox(
                          icon: Icons.delete_forever,
                          color: colors.error,
                        ),
                        const SizedBox(width: VoxSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ACTION IRRÉVERSIBLE',
                                style: text.labelSmall?.copyWith(
                                  color: colors.error,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: VoxSpacing.xs),
                              Text(
                                'Supprimer « ${widget.title} » ?',
                                style: text.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VoxSpacing.md),
                    Text(
                      'Le texte, l’audio, la position et les marque-pages '
                      'seront supprimés. Vous pourrez réimporter le PDF plus '
                      'tard.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: VoxSpacing.md),
                    _BookSummary(
                      title: widget.title,
                      pageCount: widget.pageCount,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: VoxSpacing.md),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: colors.error),
                            const SizedBox(width: VoxSpacing.sm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: text.bodyMedium?.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: VoxSpacing.lg),
                    FilledButton.icon(
                      onPressed: _busy ? null : _delete,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.background,
                      ),
                      icon: _busy
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.background,
                              ),
                            )
                          : const Icon(Icons.delete_forever),
                      label: const Text('Supprimer définitivement'),
                    ),
                    const SizedBox(height: VoxSpacing.sm),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Une conversion est en cours : le backend refuse (409). On dit pourquoi
/// et quand réessayer.
class _Blocked extends StatelessWidget {
  const _Blocked({required this.widget, super.key});

  final _DeleteDialog widget;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final conversion = widget.conversion;
    final parts = conversion?.partCount;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _IconBox(icon: Icons.hourglass_top, color: colors.warning),
              const SizedBox(width: VoxSpacing.md),
              Expanded(
                child: Text('Suppression suspendue', style: text.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: VoxSpacing.md),
          Text(
            'Conversion audio en cours : réessayez quand elle sera '
            'terminée.',
            style: text.bodyMedium,
          ),
          if (conversion != null && parts != null && parts > 0) ...[
            const SizedBox(height: VoxSpacing.md),
            Text(
              'Conversion · ${conversion.partsReady}/$parts parties',
              style: text.labelMedium,
            ),
            const SizedBox(height: VoxSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: conversion.partsReady / parts,
                minHeight: 6,
                backgroundColor: colors.border,
              ),
            ),
          ],
          const SizedBox(height: VoxSpacing.lg),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(VoxSpacing.sm + VoxSpacing.xs),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(VoxRadius.chip),
    ),
    child: Icon(icon, color: color),
  );
}

/// Rappel du livre supprimé (maquette).
class _BookSummary extends StatelessWidget {
  const _BookSummary({required this.title, required this.pageCount});

  final String title;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(VoxSpacing.sm + VoxSpacing.xs),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(VoxRadius.chip),
      ),
      child: Row(
        children: [
          VoxCover(title: title, width: 44, height: 56),
          const SizedBox(width: VoxSpacing.sm + VoxSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall,
                ),
                if (pageCount != null)
                  Text(VoxFormat.pages(pageCount!), style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
