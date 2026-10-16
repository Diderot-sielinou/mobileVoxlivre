import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/conversion_providers.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/settings/device_settings.dart';

/// Les voix du serveur (lues à l'ouverture du Profil).
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final voicesProvider = FutureProvider.autoDispose<List<Voice>>(
  (ref) async => switch (await ref.read(loadVoicesProvider)()) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError(error.code),
  },
);

/// Libellé d'une gamme.
String tierLabel(VoiceTier tier) => switch (tier) {
  VoiceTier.standard => 'Standard ×1',
  VoiceTier.natural => 'Naturelle ×4',
};

/// Ligne « Voix par défaut » du Profil (ADR-0014) : préchoisie à la
/// conversion, gardée sur le téléphone.
class DefaultVoiceTile extends ConsumerWidget {
  const DefaultVoiceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(deviceSettingsProvider);
    final voices = ref.watch(voicesProvider).value ?? const [];
    final chosen =
        voices.where((v) => v.id == settings.defaultVoiceId).firstOrNull ??
        voices.firstOrNull;
    return ListTile(
      leading: const Icon(Icons.record_voice_over_outlined),
      title: const Text('Voix par défaut'),
      subtitle: Text(
        chosen == null ? 'Proposée à chaque conversion' : chosen.label,
      ),
      trailing: const Icon(Icons.chevron_right),
      enabled: voices.isNotEmpty,
      onTap: () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          // Au-dessus de la barre d'onglets.
          useRootNavigator: true,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: VoxSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VoxSpacing.lg,
                    0,
                    VoxSpacing.lg,
                    VoxSpacing.sm,
                  ),
                  child: Text(
                    'Voix par défaut',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final voice in voices)
                  RadioListTile<String>(
                    value: voice.id,
                    groupValue: chosen?.id,
                    onChanged: (id) => Navigator.of(context).pop(id),
                    title: Text(voice.label),
                    subtitle: Text(tierLabel(voice.tier)),
                  ),
              ],
            ),
          ),
        );
        if (picked != null) {
          await ref
              .read(deviceSettingsProvider.notifier)
              .update(settings.copyWith(defaultVoiceId: picked));
        }
      },
    );
  }
}
