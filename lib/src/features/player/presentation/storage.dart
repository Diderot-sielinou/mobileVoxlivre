import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/player/application/list_downloads.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/features/player/presentation/bookmark_sheets.dart';
import 'package:voxlivre/src/features/player/presentation/offline_card.dart';
import 'package:voxlivre/src/features/player/presentation/player_controller.dart';
import 'package:voxlivre/src/features/player/presentation/player_screen.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/format/durations.dart';
import 'package:voxlivre/src/shared/settings/device_settings.dart';

/// Place prise par des livres.
int totalBytes(List<DownloadedBook> books) =>
    books.fold(0, (sum, b) => sum + b.bytes);

/// Ligne « Vitesse de lecture » du Profil (ADR-0014).
class SpeedTile extends ConsumerWidget {
  const SpeedTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(deviceSettingsProvider);
    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('Vitesse de lecture'),
      subtitle: const Text('Appliquée à l’ouverture d’un livre'),
      trailing: Text(speedLabel(settings.speed)),
      onTap: () async {
        final chosen = await showModalBottomSheet<double>(
          context: context,
          // Au-dessus de la barre d'onglets.
          useRootNavigator: true,
          showDragHandle: true,
          sheetAnimationStyle: sheetAnimation(context),
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VoxSpacing.lg,
                0,
                VoxSpacing.lg,
                VoxSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vitesse de lecture',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: VoxSpacing.md),
                  Wrap(
                    spacing: VoxSpacing.sm,
                    runSpacing: VoxSpacing.sm,
                    children: [
                      for (final speed in playerSpeeds)
                        ChoiceChip(
                          label: Text(speedLabel(speed)),
                          selected: speed == settings.speed,
                          showCheckmark: false,
                          onSelected: (_) => Navigator.of(context).pop(speed),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (chosen != null) {
          await ref
              .read(deviceSettingsProvider.notifier)
              .update(settings.copyWith(speed: chosen));
        }
      },
    );
  }
}

/// Ligne « Stockage hors ligne » du Profil : place prise, nombre de livres.
class StorageTile extends ConsumerWidget {
  const StorageTile({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(downloadsProvider).value ?? const [];
    final count = books.length;
    return ListTile(
      leading: const Icon(Icons.download_done_outlined),
      title: const Text('Stockage hors ligne'),
      subtitle: Text(
        count == 0
            ? 'Aucun livre sur le téléphone'
            : '$count livre${count > 1 ? 's' : ''} sur le téléphone',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) Text(VoxFormat.bytes(totalBytes(books))),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onOpen,
    );
  }
}

/// « Stockage hors ligne » (maquette 08, ADR-0011 et ADR-0014) : place,
/// « seulement en Wi-Fi », livres sur le téléphone, tout supprimer.
class StorageScreen extends ConsumerWidget {
  const StorageScreen({this.titleOf, super.key});

  /// Titre du livre d'une conversion (lu dans la bibliothèque).
  final String? Function(String conversionId)? titleOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final books = ref.watch(downloadsProvider).value ?? const [];
    final settings = ref.watch(deviceSettingsProvider);
    final used = totalBytes(books);

    Future<void> clearAll() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer tous les livres du téléphone ?'),
          content: Text(
            '${VoxFormat.bytes(used)} seront libérés. Les livres restent '
            'dans votre bibliothèque et se retéléchargent.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: const Text('Tout supprimer'),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false) || !context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(clearDownloadsProvider)();
      messenger.showSnackBar(
        SnackBar(content: Text('${VoxFormat.bytes(used)} libérés')),
      );
    }

    Future<void> remove(DownloadedBook book, String title) async {
      if (!await confirmRemoveDownload(context, title) || !context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(removeDownloadProvider)(book.conversionId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Audio supprimé du téléphone')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Stockage hors ligne')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          VoxSpacing.sm,
          VoxSpacing.screenMargin,
          VoxSpacing.xl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(VoxSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VoxRadius.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sur ce téléphone', style: text.labelLarge),
                const SizedBox(height: VoxSpacing.xs),
                Text(
                  '${VoxFormat.bytes(used)} utilisés',
                  style: text.titleLarge,
                ),
                const SizedBox(height: VoxSpacing.sm),
                Text(
                  'L’audio téléchargé permet d’écouter sans connexion.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VoxSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.wifi),
            title: const Text('Télécharger seulement en Wi-Fi'),
            subtitle: const Text(
              'En données mobiles, Voxlivre demande avant de télécharger.',
            ),
            value: settings.wifiOnly,
            onChanged: (value) => ref
                .read(deviceSettingsProvider.notifier)
                .update(settings.copyWith(wifiOnly: value)),
          ),
          const SizedBox(height: VoxSpacing.md),
          Text(
            'Livres sur ce téléphone (${books.length})',
            style: text.titleMedium,
          ),
          const SizedBox(height: VoxSpacing.sm),
          if (books.isEmpty)
            Text(
              'Aucun livre téléchargé. Depuis la fiche d’un livre converti, '
              '« Télécharger » le rend écoutable sans connexion.',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          for (final book in books)
            Padding(
              padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
              child: _BookTile(
                title: titleOf?.call(book.conversionId) ?? 'Livre',
                bytes: book.bytes,
                onRemove: (title) => unawaited(remove(book, title)),
              ),
            ),
          if (books.length > 1) ...[
            const SizedBox(height: VoxSpacing.sm),
            OutlinedButton.icon(
              onPressed: clearAll,
              icon: Icon(Icons.delete_sweep_outlined, color: colors.error),
              label: Text(
                'Tout supprimer pour libérer ${VoxFormat.bytes(used)}',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
          const SizedBox(height: VoxSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_done_outlined, color: colors.textSecondary),
              const SizedBox(width: VoxSpacing.sm),
              Expanded(
                child: Text(
                  'Vos marque-pages et votre progression restent sur votre '
                  'compte Voxlivre.',
                  style: text.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.title,
    required this.bytes,
    required this.onRemove,
  });

  final String title;
  final int bytes;
  final ValueChanged<String> onRemove;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: text.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: VoxSpacing.sm),
              Text(
                VoxFormat.bytes(bytes),
                style: text.labelLarge?.copyWith(color: colors.accent),
              ),
            ],
          ),
          const SizedBox(height: VoxSpacing.xs),
          Row(
            children: [
              Icon(Icons.offline_pin_outlined, size: 16, color: colors.success),
              const SizedBox(width: VoxSpacing.xs),
              Flexible(
                child: Text(
                  'Prêt pour l’écoute hors ligne',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: VoxSpacing.sm),
          TextButton.icon(
            onPressed: () => onRemove(title),
            icon: Icon(Icons.delete_outline, color: colors.error),
            label: Text(
              'Supprimer l’audio du téléphone',
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
