import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/features/library/domain/document_title.dart';
import 'package:voxlivre/src/features/library/presentation/import_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Message d'un échec d'import, par code stable.
String importErrorText(String code, {String? reason}) => switch (code) {
  ImportRefused.tooLarge || 'INVALID_DOCUMENT_SIZE' =>
    'Ce PDF dépasse 50 Mo. Découpez-le en plusieurs parties.',
  ImportRefused.empty => 'Ce fichier est vide.',
  ImportRefused.notPdf => 'Ce fichier n’est pas un PDF lisible.',
  ImportRefused.rightsNotAttested ||
  'INVALID_RIGHTS_ATTESTATION' => 'Cochez l’attestation pour continuer.',
  'INVALID_DOCUMENT_TITLE' =>
    'Entrez un titre de 1 à ${DocumentTitle.maxLength} caractères.',
  'INVALID_DOCUMENT_UPLOAD' when reason == 'not_pdf' =>
    'Le serveur n’a pas reconnu un PDF dans ce fichier.',
  'INVALID_DOCUMENT_UPLOAD' => 'Le fichier est arrivé incomplet. Réessayez.',
  'NETWORK_UNAVAILABLE' ||
  'TIMEOUT' => 'Pas de connexion. Réessayez quand le réseau revient.',
  'RATE_LIMITED' => 'Trop d’essais rapprochés. Patientez une minute.',
  _ => 'L’import a échoué. Réessayez dans un instant.',
};

/// Onglet Importer (maquettes « Importation en cours ») : choisir un PDF,
/// attester ses droits, l'envoyer (ADR-0007). Une fois le fichier vérifié,
/// [onImported] ouvre la fiche, qui suit l'analyse.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({required this.onImported, super.key});

  final ValueChanged<String> onImported;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _title = TextEditingController();
  bool _attested = false;

  ImportController get _controller =>
      ref.read(importControllerProvider.notifier);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(importControllerProvider, (previous, next) {
      // Nouveau fichier : titre proposé d'après son nom.
      if (next.phase == ImportPhase.picked && previous?.file != next.file) {
        _title.text = ImportRules.titleFromFileName(next.file!.name);
        setState(() => _attested = false);
      }
      if (next.documentId case final id? when next.phase == ImportPhase.done) {
        widget.onImported(id);
        _controller.reset();
      }
    });
    final view = ref.watch(importControllerProvider);
    final swap = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : VoxMotion.swap;

    return Scaffold(
      appBar: AppBar(title: const Text('Importer')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: swap,
          child: switch (view.phase) {
            ImportPhase.idle || ImportPhase.done => _Intro(
              key: const ValueKey('intro'),
              onPick: _controller.pick,
            ),
            ImportPhase.working => _Sending(
              key: const ValueKey('sending'),
              view: view,
              onCancel: _controller.cancel,
            ),
            ImportPhase.picked || ImportPhase.failed => _Form(
              key: const ValueKey('form'),
              view: view,
              title: _title,
              attested: _attested,
              onAttested: (value) => setState(() => _attested = value),
              onPick: _controller.pick,
              onSend: () => _controller.start(
                title: _title.text,
                attested: _attested,
              ),
            ),
          },
        ),
      ),
    );
  }
}

/// Avant le choix : ce que l'on peut importer.
class _Intro extends StatelessWidget {
  const _Intro({required this.onPick, super.key});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(VoxSpacing.screenMargin),
      children: [
        const SizedBox(height: VoxSpacing.lg),
        Center(
          child: Container(
            padding: const EdgeInsets.all(VoxSpacing.lg),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.upload_file, size: 48, color: colors.accent),
          ),
        ),
        const SizedBox(height: VoxSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            'Importez un PDF',
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
        ),
        const SizedBox(height: VoxSpacing.sm),
        Text(
          'Cours, polycopié ou scan : Voxlivre en fait un livre audio, '
          'à écouter même hors ligne.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: VoxSpacing.lg),
        const _Fact(
          icon: Icons.picture_as_pdf_outlined,
          text: 'PDF jusqu’à 50 Mo',
        ),
        const _Fact(
          icon: Icons.document_scanner_outlined,
          text: 'Texte ou scan (300 pages au plus pour un scan)',
        ),
        const _Fact(
          icon: Icons.lock_outline,
          text: 'Envoi sécurisé, visible par vous seul',
        ),
        const SizedBox(height: VoxSpacing.xl),
        VoxPrimaryButton(
          label: 'Choisir un PDF',
          icon: Icons.folder_open,
          onPressed: onPick,
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: VoxSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 20, color: context.vox.accent),
        const SizedBox(width: VoxSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}

/// Fichier choisi : titre, attestation, coût en data, envoi.
class _Form extends StatelessWidget {
  const _Form({
    required this.view,
    required this.title,
    required this.attested,
    required this.onAttested,
    required this.onPick,
    required this.onSend,
    super.key,
  });

  final ImportViewState view;
  final TextEditingController title;
  final bool attested;
  final ValueChanged<bool> onAttested;
  final VoidCallback onPick;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final file = view.file!;
    final code = view.errorCode;
    final titleError = code == 'INVALID_DOCUMENT_TITLE';
    return ListView(
      padding: const EdgeInsets.all(VoxSpacing.screenMargin),
      children: [
        _FileCard(
          file: file,
          trailing: TextButton(onPressed: onPick, child: const Text('Changer')),
        ),
        const SizedBox(height: VoxSpacing.lg),
        TextField(
          controller: title,
          maxLength: DocumentTitle.maxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Titre dans la bibliothèque',
            errorText: titleError ? importErrorText(code!) : null,
          ),
        ),
        const SizedBox(height: VoxSpacing.sm),
        Card(
          child: CheckboxListTile(
            value: attested,
            onChanged: (value) => onAttested(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('J’ai le droit d’utiliser ce document'),
            subtitle: const Text(
              'Mon cours, mon document ou un texte libre de droits.',
            ),
          ),
        ),
        const SizedBox(height: VoxSpacing.md),
        Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: colors.textSecondary),
            const SizedBox(width: VoxSpacing.sm),
            Expanded(
              child: Text(
                '${VoxFormat.bytes(file.sizeBytes)} seront envoyés. Pour un '
                'gros fichier, préférez le Wi-Fi.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
        if (code != null && !titleError) ...[
          const SizedBox(height: VoxSpacing.md),
          VoxBanner(
            tone: VoxBannerTone.error,
            icon: code == 'NETWORK_UNAVAILABLE' || code == 'TIMEOUT'
                ? Icons.cloud_off_outlined
                : null,
            message: importErrorText(code, reason: view.errorReason),
          ),
        ],
        const SizedBox(height: VoxSpacing.lg),
        VoxPrimaryButton(
          label: code == null ? 'Envoyer' : 'Réessayer',
          icon: code == null ? Icons.cloud_upload_outlined : Icons.refresh,
          onPressed: attested ? onSend : null,
        ),
        if (!attested) ...[
          const SizedBox(height: VoxSpacing.xs),
          Text(
            'Cochez l’attestation pour envoyer.',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Le fichier : icône PDF, nom, taille.
class _FileCard extends StatelessWidget {
  const _FileCard({required this.file, this.trailing});

  final PickedPdf file;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(VoxSpacing.sm + VoxSpacing.xs),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(VoxRadius.chip),
              ),
              child: Icon(Icons.picture_as_pdf, color: colors.accent),
            ),
            const SizedBox(width: VoxSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  Text(VoxFormat.bytes(file.sizeBytes), style: text.bodySmall),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Envoi puis vérification (« Étape n sur 2 »), jamais un indicateur seul.
class _Sending extends StatelessWidget {
  const _Sending({required this.view, required this.onCancel, super.key});

  final ImportViewState view;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final progress = view.progress;
    final stage = progress?.stage ?? ImportStage.requesting;
    final confirming = stage == ImportStage.confirming;
    final total = progress?.total ?? view.file!.sizeBytes;
    final sent = progress?.sent ?? 0;
    final ratio = stage == ImportStage.sending && total > 0
        ? (sent / total).clamp(0.0, 1.0)
        : null;
    final attempt = progress?.attempt ?? 1;
    final rate = view.bytesPerSecond;

    return ListView(
      padding: const EdgeInsets.all(VoxSpacing.screenMargin),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            confirming ? 'Étape 2 sur 2' : 'Étape 1 sur 2',
            style: text.labelLarge?.copyWith(color: colors.accent),
          ),
        ),
        const SizedBox(height: VoxSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            confirming ? 'Vérification du fichier' : 'Envoi en cours',
            style: text.headlineSmall,
          ),
        ),
        Text(
          confirming
              ? 'Le serveur contrôle le PDF avant de lire son texte.'
              : 'Envoi sécurisé de votre document.',
          style: text.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: VoxSpacing.lg),
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(VoxSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FileCardContent(file: view.file!),
                  const SizedBox(height: VoxSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: colors.border,
                    ),
                  ),
                  const SizedBox(height: VoxSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          switch (stage) {
                            ImportStage.requesting => 'Préparation de l’envoi…',
                            ImportStage.confirming =>
                              'Fichier reçu, vérification…',
                            ImportStage.sending =>
                              '${(ratio! * 100).floor()} % · '
                                  '${VoxFormat.bytes(sent)} / '
                                  '${VoxFormat.bytes(total)}',
                          },
                          style: text.labelMedium,
                        ),
                      ),
                      if (stage == ImportStage.sending && rate != null) ...[
                        Icon(
                          Icons.speed,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: VoxSpacing.xs),
                        Text(
                          '~${VoxFormat.bytes(rate.round())}/s',
                          style: text.labelMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (attempt > 1 && !confirming) ...[
          const SizedBox(height: VoxSpacing.md),
          VoxBanner(
            icon: Icons.wifi_off,
            message:
                'Le réseau a coupé : l’envoi reprend depuis le début '
                '(essai $attempt).',
          ),
        ],
        const SizedBox(height: VoxSpacing.md),
        Card(
          child: ListTile(
            leading: Icon(Icons.phone_android, color: colors.warning),
            title: const Text('Gardez l’application ouverte.'),
            subtitle: const Text(
              'Si le réseau coupe, l’envoi est relancé automatiquement.',
            ),
          ),
        ),
        const SizedBox(height: VoxSpacing.lg),
        if (!confirming)
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Annuler l’envoi'),
          ),
      ],
    );
  }
}

class _FileCardContent extends StatelessWidget {
  const _FileCardContent({required this.file});

  final PickedPdf file;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(Icons.picture_as_pdf, color: context.vox.accent),
        const SizedBox(width: VoxSpacing.sm),
        Expanded(
          child: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
        ),
        Text(VoxFormat.bytes(file.sizeBytes), style: text.bodySmall),
      ],
    );
  }
}
