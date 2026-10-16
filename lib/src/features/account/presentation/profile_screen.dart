import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/account/account_providers.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/links/legal_links.dart';

/// La version de l'app (bas du Profil).
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final appVersionProvider = FutureProvider.autoDispose<String>(
  (ref) => ref.read(readAppVersionProvider)(),
);

/// L'onglet Profil (maquette 08, ADR-0014) : une mise en page dont les
/// morceaux viennent des autres fonctionnalités, par le routeur.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    required this.header,
    required this.units,
    required this.reading,
    required this.storage,
    required this.signOut,
    this.termsUrl,
    this.privacyUrl,
    this.supportEmail,
    super.key,
  });

  final Widget header;
  final Widget units;

  /// Voix par défaut, vitesse…
  final List<Widget> reading;
  final Widget storage;
  final Widget signOut;
  final Uri? termsUrl;
  final Uri? privacyUrl;
  final String? supportEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final version = ref.watch(appVersionProvider).value;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: VoxSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: text.labelLarge?.copyWith(color: colors.textSecondary),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(VoxRadius.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );

    Widget link(IconData icon, String label, Uri uri) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: () => unawaited(openLink(context, ref, uri)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          VoxSpacing.sm,
          VoxSpacing.screenMargin,
          VoxSpacing.xl,
        ),
        children: [
          header,
          const SizedBox(height: VoxSpacing.lg),
          units,
          section('Lecture et écoute', reading),
          section('Application', [
            storage,
            if (supportEmail case final email?)
              link(
                Icons.help_outline,
                'Aide et contact',
                // `%20` et non `+` : une messagerie lit le `+` tel quel.
                Uri(
                  scheme: 'mailto',
                  path: email,
                  query: 'subject=${Uri.encodeComponent('Aide Voxlivre')}',
                ),
              ),
          ]),
          if (termsUrl != null || privacyUrl != null)
            section('Légal et confidentialité', [
              if (termsUrl case final url?)
                link(
                  Icons.description_outlined,
                  'Conditions d’utilisation',
                  url,
                ),
              if (privacyUrl case final url?)
                link(Icons.shield_outlined, 'Confidentialité et données', url),
            ]),
          const SizedBox(height: VoxSpacing.xl),
          signOut,
          if (version != null) ...[
            const SizedBox(height: VoxSpacing.md),
            Text(
              'Voxlivre $version',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
