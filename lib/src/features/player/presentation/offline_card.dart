import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/player/presentation/offline_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Carte « Écouter sans connexion » de la fiche (ADR-0011) : télécharger,
/// suivre, reprendre ; même taille dans tous ses états. « Écouter » reste
/// l'unique bouton principal de la fiche.
class OfflineCard extends ConsumerWidget {
  const OfflineCard({required this.conversionId, super.key});

  final String conversionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(offlineControllerProvider(conversionId));
    final controller = ref.read(
      offlineControllerProvider(conversionId).notifier,
    );
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final size = switch (view.totalBytes) {
      final bytes? => VoxFormat.bytes(bytes),
      null => null,
    };
    final progress = view.progress;
    final kept = progress == null
        ? ''
        : '${VoxFormat.bytes(progress.bytesDone)} sur '
              '${VoxFormat.bytes(progress.bytesTotal)}';

    final (icon, iconColor, title, detail) = switch (view.stage) {
      OfflineStage.checking => (
        Icons.download_outlined,
        colors.textSecondary,
        'Écouter sans connexion',
        'Calcul de la taille…',
      ),
      OfflineStage.available => (
        Icons.download_outlined,
        colors.accent,
        'Écouter sans connexion',
        size == null ? 'À télécharger sur le téléphone' : '$size à télécharger',
      ),
      OfflineStage.downloading => (
        Icons.downloading,
        colors.accent,
        'Téléchargement…',
        progress == null
            ? 'Préparation…'
            : 'Partie ${progress.currentPart} sur ${progress.partCount} '
                  '· $kept',
      ),
      OfflineStage.interrupted => (
        Icons.pause_circle_outline,
        colors.warning,
        offlineInterruptionTitle(view.errorCode),
        kept.isEmpty ? 'Rien n’est perdu' : '$kept gardés',
      ),
      OfflineStage.downloaded => (
        Icons.offline_pin_outlined,
        colors.success,
        'Disponible hors ligne',
        size == null ? 'Sur le téléphone' : '$size sur le téléphone',
      ),
    };

    // Pendant la vérification, le bouton est déjà là (désactivé) : la
    // carte garde sa taille jusqu'à la fin du téléchargement.
    final Widget? action = switch (view.stage) {
      OfflineStage.checking => const OutlinedButton(
        onPressed: null,
        child: Text('Télécharger'),
      ),
      OfflineStage.available => OutlinedButton(
        onPressed: controller.download,
        child: const Text('Télécharger'),
      ),
      OfflineStage.downloading => TextButton(
        onPressed: controller.cancel,
        child: const Text('Annuler'),
      ),
      OfflineStage.interrupted => OutlinedButton(
        onPressed: controller.download,
        child: const Text('Reprendre'),
      ),
      OfflineStage.downloaded => null,
    };
    final showBar =
        view.stage == OfflineStage.downloading ||
        view.stage == OfflineStage.interrupted;

    return Container(
      padding: const EdgeInsets.all(VoxSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VoxRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: VoxSpacing.sm + VoxSpacing.xs),
              Expanded(
                // Annoncé à chaque étape (partie suivante, fin, coupure),
                // sans prendre le focus.
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      const SizedBox(height: VoxSpacing.xs),
                      Text(detail, style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Texte sur toute la largeur, puis barre et bouton : rien ne
          // s'écrase sur un petit écran.
          if (action != null) ...[
            const SizedBox(height: VoxSpacing.sm),
            SizedBox(
              height: VoxSizes.minTouchTarget,
              child: Row(
                children: [
                  Expanded(
                    child: Visibility(
                      visible: showBar,
                      child: ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(VoxRadius.chip),
                          child: LinearProgressIndicator(
                            value: progress?.fraction ?? 0,
                            minHeight: 6,
                            color: colors.accent,
                            backgroundColor: colors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: VoxSpacing.md),
                  action,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Titre d'un téléchargement arrêté, selon sa raison.
String offlineInterruptionTitle(String? code) => switch (code) {
  null => 'Téléchargement en pause',
  'NETWORK_UNAVAILABLE' || 'TIMEOUT' => 'Connexion perdue',
  'DOWNLOAD_CORRUPT' => 'Fichier abîmé, réessayez',
  _ => 'Téléchargement interrompu',
};

/// Demande avant de retirer l'audio du téléphone ; `true` = confirmé.
Future<bool> confirmRemoveDownload(BuildContext context, String title) async {
  final colors = context.vox;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer l’audio du téléphone ?'),
      content: Text(
        '« $title » restera dans votre bibliothèque. Vous pourrez le '
        'télécharger à nouveau.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
