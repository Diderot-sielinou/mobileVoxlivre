import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/links/link_opener.dart';

/// Ouvre [uri] ; un message si rien sur le téléphone ne sait l'ouvrir.
Future<void> openLink(BuildContext context, WidgetRef ref, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await ref.read(linkOpenerProvider).open(uri)) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Aucune application pour ouvrir ce lien.'),
        ),
      );
  }
}

/// « Conditions d'utilisation » et « Confidentialité », boutons de 48 dp ;
/// rien si le site n'est pas configuré (ADR-0014).
class LegalLinks extends ConsumerWidget {
  const LegalLinks({this.termsUrl, this.privacyUrl, super.key});

  final Uri? termsUrl;
  final Uri? privacyUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = [
      if (termsUrl case final url?) ('Conditions d’utilisation', url),
      if (privacyUrl case final url?) ('Confidentialité', url),
    ];
    if (links.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: VoxSpacing.sm,
      children: [
        for (final (label, url) in links)
          TextButton(
            onPressed: () => unawaited(openLink(context, ref, url)),
            child: Text(label),
          ),
      ],
    );
  }
}
