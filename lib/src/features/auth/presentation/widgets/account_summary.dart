import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';

/// « a••••@gmail.com » : assez pour se reconnaître, sans tout montrer.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email[0]}••••${email.substring(at)}';
}

/// « +237 6•• •• •• 11 ».
String maskPhone(String e164) {
  if (e164.length < 4) return e164;
  final last = e164.substring(e164.length - 2);
  return e164.startsWith('+237')
      ? '+237 ${e164[4]}•• •• •• $last'
      : '••• $last';
}

/// Deux initiales du nom, sinon de l'adresse.
String initialsOf(String? name, String? fallback) {
  final words = (name ?? '').trim().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.length >= 2) return (words[0][0] + words[1][0]).toUpperCase();
  if (words.length == 1) return words[0][0].toUpperCase();
  final source = (fallback ?? '').replaceAll(RegExp('[^A-Za-z]'), '');
  return source.isEmpty ? '?' : source[0].toUpperCase();
}

/// En-tête du Profil (ADR-0014) : initiales, nom, identité masquée.
class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionStateProvider).value;
    final user = switch (state) {
      SignedIn(:final user) => user,
      _ => null,
    };
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final identity = switch (user) {
      CurrentUser(email: final email?) => maskEmail(email),
      CurrentUser(phoneNumber: final phone?) => maskPhone(phone),
      _ => null,
    };
    final name = user?.name?.trim();
    return Semantics(
      container: true,
      label: [
        if (name != null && name.isNotEmpty) name else 'Mon compte',
        ?identity,
      ].join(', '),
      excludeSemantics: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.elevated,
            child: Text(
              initialsOf(name, user?.email ?? user?.phoneNumber),
              style: text.titleMedium?.copyWith(color: colors.accent),
            ),
          ),
          const SizedBox(width: VoxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null || name.isEmpty ? 'Mon compte' : name,
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (identity != null)
                  Text(
                    identity,
                    style: text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Se déconnecter », avec confirmation : les données du compte quittent
/// le téléphone (ADR-0006).
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: () async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text(
            'Les livres téléchargés, positions et marque-pages en attente '
            'quittent ce téléphone. Tout ce qui est envoyé reste sur votre '
            'compte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );
      if (confirmed ?? false) unawaited(ref.read(signOutProvider)());
    },
    icon: const Icon(Icons.logout),
    label: const Text('Se déconnecter'),
  );
}
