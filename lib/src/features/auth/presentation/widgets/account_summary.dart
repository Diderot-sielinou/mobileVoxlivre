import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// Compte connecté et déconnexion (onglet Profil, en attendant l'écran
/// Profil complet).
class AccountSummary extends ConsumerWidget {
  const AccountSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionStateProvider).value;
    final user = switch (state) {
      SignedIn(:final user) => user,
      _ => null,
    };
    final identity = user?.email ?? user?.phoneNumber;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: context.vox.accent),
                const SizedBox(width: VoxSpacing.sm),
                Expanded(
                  child: Text(
                    identity == null ? 'Connecté' : 'Connecté : $identity',
                    style: text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VoxSpacing.md),
            OutlinedButton.icon(
              onPressed: () => ref.read(signOutProvider)(),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
