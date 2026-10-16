import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/library/presentation/document_controller.dart';
import 'package:voxlivre/src/features/library/presentation/library_texts.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/delete_document_dialog.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/outline_section.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/rename_document_dialog.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_cover.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_timeline.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Rythme du rafraîchissement tant que le texte se prépare.
const documentWorkRefresh = Duration(seconds: 10);

/// Étiquette `Hero` de la couverture : la même dans la carte de la
/// bibliothèque et dans la fiche (design system §2, n° 5).
String coverHeroTag(String documentId) => 'cover-$documentId';

/// Fiche d'un document (maquette « Fiche document ») : le cache d'abord,
/// puis la fiche et la table des matières du réseau (ADR-0006).
class DocumentScreen extends ConsumerStatefulWidget {
  const DocumentScreen({
    required this.documentId,
    required this.onOpenText,
    required this.onConvert,
    required this.onOpenConversion,
    required this.onListen,
    this.offlineCard,
    this.downloaded = const {},
    this.onRemoveDownload,
    this.onDeleted,
    super.key,
  });

  final String documentId;

  /// Ouvre la vérification du texte.
  final VoidCallback onOpenText;

  /// Ouvre le choix de la voix (titre, nombre de caractères : ADR-0008).
  final void Function(String title, int chars) onConvert;

  /// Ouvre le suivi d'une conversion.
  final ValueChanged<String> onOpenConversion;

  /// Ouvre le lecteur (ADR-0010).
  final void Function(String conversionId, String title) onListen;

  /// Carte « Écouter sans connexion » d'une conversion terminée, fournie
  /// par le lecteur (ADR-0011).
  final Widget Function(String conversionId)? offlineCard;

  /// Conversions dont l'audio est sur le téléphone.
  final Set<String> downloaded;

  /// Retire l'audio du téléphone (avec confirmation) ; `true` = fait.
  final Future<bool> Function(String conversionId, String title)?
  onRemoveDownload;

  /// Document supprimé : l'audio téléchargé de sa conversion part aussi.
  final ValueChanged<String>? onDeleted;

  @override
  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends ConsumerState<DocumentScreen> {
  Timer? _poll;

  DocumentController get _controller =>
      ref.read(documentControllerProvider(widget.documentId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.refresh());
    });
    _poll = Timer.periodic(documentWorkRefresh, (_) {
      final sheet = ref.read(documentSheetProvider(widget.documentId)).value;
      final visible = mounted && TickerMode.of(context);
      if (visible && (sheet?.stage.working ?? false)) {
        unawaited(_controller.refresh());
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _rename(String title) async {
    final renamed = await showRenameDocumentDialog(
      context,
      initialTitle: title,
      onSubmit: _controller.rename,
    );
    if (renamed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document renommé')),
      );
    }
  }

  Future<void> _delete({
    required String title,
    required int? pageCount,
    required ConversionSummary? conversion,
  }) async {
    final deleted = await showDeleteDocumentDialog(
      context,
      title: title,
      pageCount: pageCount,
      conversion: conversion,
      onDelete: _controller.delete,
    );
    if (!deleted || !mounted) return;
    if (conversion != null) widget.onDeleted?.call(conversion.id);
    // La bibliothèque le retire de son cache ; on la rafraîchit au retour.
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline),
            SizedBox(width: VoxSpacing.sm),
            Expanded(child: Text('Document supprimé')),
          ],
        ),
      ),
    );
  }

  Future<void> _removeDownload(String conversionId, String title) async {
    final removed = await widget.onRemoveDownload?.call(conversionId, title);
    if ((removed ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio supprimé du téléphone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheet = ref.watch(documentSheetProvider(widget.documentId)).value;
    final view = ref.watch(documentControllerProvider(widget.documentId));
    final item = ref
        .watch(librarySnapshotProvider)
        .value
        ?.items
        .where((i) => i.documentId == widget.documentId)
        .firstOrNull;
    final title = sheet?.title ?? item?.title ?? '';
    final pageCount = sheet?.pageCount ?? item?.pageCount;
    final downloadedId = switch (item?.conversion?.id) {
      final id? when widget.downloaded.contains(id) => id,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche document'),
        actions: [
          PopupMenuButton<_MenuAction>(
            tooltip: 'Plus d’actions',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _MenuAction.text => widget.onOpenText(),
              _MenuAction.rename => _rename(title),
              _MenuAction.removeDownload => _removeDownload(
                downloadedId!,
                title,
              ),
              _MenuAction.delete => _delete(
                title: title,
                pageCount: pageCount,
                conversion: item?.conversion,
              ),
            },
            itemBuilder: (context) => [
              if (sheet?.stage == DocumentStage.textReady)
                const PopupMenuItem(
                  value: _MenuAction.text,
                  child: ListTile(
                    leading: Icon(Icons.article_outlined),
                    title: Text('Voir le texte'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: _MenuAction.rename,
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Renommer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (downloadedId != null && widget.onRemoveDownload != null)
                const PopupMenuItem(
                  value: _MenuAction.removeDownload,
                  child: ListTile(
                    leading: Icon(Icons.mobile_off_outlined),
                    title: Text('Supprimer l’audio du téléphone'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: _MenuAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: context.vox.error),
                  title: Text(
                    'Supprimer le document',
                    style: TextStyle(color: context.vox.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            VoxSpacing.screenMargin,
            VoxSpacing.sm,
            VoxSpacing.screenMargin,
            VoxSpacing.xl,
          ),
          children: [
            if (view.errorCode != null) ...[
              _ErrorBanner(code: view.errorCode!, cached: sheet != null),
              const SizedBox(height: VoxSpacing.md),
            ],
            _Header(
              documentId: widget.documentId,
              title: title,
              sheet: sheet,
              pageCount: pageCount,
            ),
            const SizedBox(height: VoxSpacing.lg),
            ..._body(sheet, item, failed: view.errorCode != null),
          ],
        ),
      ),
      bottomNavigationBar: _BottomAction(
        sheet: sheet,
        item: item,
        onConvert: widget.onConvert,
        onOpenConversion: widget.onOpenConversion,
        onListen: widget.onListen,
      ),
    );
  }

  List<Widget> _body(
    DocumentSheet? sheet,
    LibraryItem? item, {
    required bool failed,
  }) {
    if (sheet == null) {
      // Ni cache ni réseau encore : le titre suffit, le reste arrive. Après
      // un échec, le bandeau dit pourquoi : pas d'attente sans fin.
      return [if (!failed) const Center(child: CircularProgressIndicator())];
    }
    return [
      if (sheet.stage.working) _WorkingCard(sheet: sheet),
      if (sheet.stage == DocumentStage.failed)
        _InfoCard(
          tone: VoxBannerTone.error,
          icon: Icons.error_outline,
          title: 'Le texte n’a pas pu être extrait',
          body:
              '${failureText(extraction: sheet.extractionError)}. Vous pouvez '
              'supprimer ce document et réimporter le PDF.',
        ),
      if (sheet.reviewPending)
        _InfoCard(
          tone: VoxBannerTone.warning,
          icon: Icons.warning_amber_rounded,
          title:
              'Relecture obligatoire : certaines pages ont été mal reconnues.',
          body:
              'Vérifiez le texte avant de le convertir, pour une lecture '
              'juste.',
          action: VoxPrimaryButton(
            label: 'Vérifier le texte',
            icon: Icons.spellcheck,
            onPressed: widget.onOpenText,
          ),
        ),
      if (item?.conversion case final conversion?
          when item!.status != LibraryStatus.notConverted) ...[
        const SizedBox(height: VoxSpacing.sm),
        _ConversionLine(item: item, conversion: conversion),
        // Livre entièrement converti : il peut partir sur le téléphone.
        if (conversion.status == 'ready' && widget.offlineCard != null) ...[
          const SizedBox(height: VoxSpacing.md),
          widget.offlineCard!(conversion.id),
        ],
      ],
      if (sheet.outline.isNotEmpty) ...[
        const SizedBox(height: VoxSpacing.lg),
        OutlineSection(entries: sheet.outline),
      ],
    ];
  }
}

enum _MenuAction { text, rename, removeDownload, delete }

/// Couverture, titre, informations (maquette : « 120 pages • 214 300
/// caractères • Scan (OCR) »).
class _Header extends StatelessWidget {
  const _Header({
    required this.documentId,
    required this.title,
    required this.sheet,
    required this.pageCount,
  });

  final String documentId;
  final String title;
  final DocumentSheet? sheet;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chars = sheet?.charCount;
    final method = sheet?.method;
    return Column(
      children: [
        HeroMode(
          enabled: !MediaQuery.disableAnimationsOf(context),
          child: Hero(
            tag: coverHeroTag(documentId),
            child: VoxCover(title: title, width: 120, height: 156),
          ),
        ),
        const SizedBox(height: VoxSpacing.md),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: text.headlineMedium,
          ),
        ),
        const SizedBox(height: VoxSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: VoxSpacing.md,
          runSpacing: VoxSpacing.xs,
          children: [
            if (pageCount != null)
              _Meta(
                icon: Icons.description_outlined,
                label: VoxFormat.pages(pageCount!),
              ),
            if (chars != null)
              _Meta(
                icon: Icons.text_fields,
                label: '${VoxFormat.count(chars)} caractères',
              ),
            if (method != null)
              _Meta(
                icon: method == ExtractionMethod.ocr
                    ? Icons.document_scanner_outlined
                    : Icons.article_outlined,
                label: method == ExtractionMethod.ocr ? 'Scan (OCR)' : 'Texte',
                accent: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, this.accent = false});

  final IconData icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final color = accent ? colors.accent : colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: VoxSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent ? colors.accent : colors.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// Texte en préparation : barre déterminée pour la reconnaissance d'un
/// scan (lots de 10 pages), sinon explication (jamais un indicateur seul).
class _WorkingCard extends StatelessWidget {
  const _WorkingCard({required this.sheet});

  final DocumentSheet sheet;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final ocr = sheet.ocrProgress;
    final current = sheet.analysisStep;
    VoxStepState state(AnalysisStep step) => step.index < current.index
        ? VoxStepState.done
        : step == current
        ? VoxStepState.active
        : VoxStepState.pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(VoxSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Analyse en cours', style: text.titleMedium),
                  const SizedBox(height: VoxSpacing.md),
                  VoxTimeline(
                    steps: [
                      VoxStep(
                        title: 'Fichier reçu',
                        detail: current == AnalysisStep.received
                            ? 'Envoi du PDF en attente'
                            : 'PDF vérifié',
                        state: state(AnalysisStep.received),
                      ),
                      VoxStep(
                        title: 'Lecture du PDF',
                        detail: sheet.scanned
                            ? 'Scan détecté : le texte est une image'
                            : 'Texte de chaque page, ou scan à reconnaître',
                        state: state(AnalysisStep.reading),
                      ),
                      if (sheet.scanned)
                        VoxStep(
                          title: 'Reconnaissance du texte',
                          detail: ocr == null
                              ? 'Page par page, par lots de 10'
                              : '${ocr.done}/${ocr.total} pages',
                          state: state(AnalysisStep.recognizing),
                          progress: ocr == null || ocr.total == 0
                              ? null
                              : ocr.done / ocr.total,
                        ),
                      VoxStep(
                        title: 'Nettoyage',
                        detail:
                            'En-têtes, numéros de page, notes ; table des '
                            'matières',
                        state: state(AnalysisStep.cleaning),
                      ),
                      VoxStep(
                        title: 'Texte prêt',
                        detail: 'À relire si des pages sont douteuses',
                        state: state(AnalysisStep.ready),
                      ),
                    ],
                  ),
                  const SizedBox(height: VoxSpacing.sm),
                  Text(
                    'Vous pouvez quitter cet écran : le travail continue.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: VoxSpacing.md),
        Card(
          child: ListTile(
            leading: Icon(Icons.lightbulb_outline, color: colors.accent),
            title: const Text('Pourquoi ce nettoyage ?'),
            subtitle: const Text(
              'Voxlivre retire les numéros de page, en-têtes et notes de bas '
              'de page pour que l’écoute reste fluide. Vous les retrouvez '
              'dans « Voir le texte ».',
            ),
          ),
        ),
      ],
    );
  }
}

/// Carte d'avertissement (relecture) ou d'échec : icône **et** texte.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final VoxBannerTone tone;
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final color = tone == VoxBannerTone.warning ? colors.warning : colors.error;
    return Container(
      padding: const EdgeInsets.all(VoxSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VoxRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(VoxSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(VoxRadius.chip),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: VoxSpacing.sm + VoxSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleSmall),
                    const SizedBox(height: VoxSpacing.xs),
                    Text(body, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: VoxSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Bouton d'une étape à venir : affiché comme dans la maquette, mais
/// désactivé, avec la raison écrite dessous.
class _Pending extends StatelessWidget {
  const _Pending({
    required this.label,
    required this.icon,
    required this.caption,
  });

  final String label;
  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    // `min` : en barre du bas, la colonne prendrait sinon tout l'écran.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoxPrimaryButton(label: label, icon: icon, onPressed: null),
        const SizedBox(height: VoxSpacing.xs),
        _Caption(text: caption),
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.info_outline, size: 16, color: context.vox.textSecondary),
      const SizedBox(width: VoxSpacing.xs),
      Flexible(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}

/// État de la conversion retenue (depuis la bibliothèque en cache).
class _ConversionLine extends StatelessWidget {
  const _ConversionLine({required this.item, required this.conversion});

  final LibraryItem item;
  final ConversionSummary conversion;

  @override
  Widget build(BuildContext context) {
    final look = statusLook(item.status, context.vox);
    final detail = statusDetail(item);
    return Card(
      child: ListTile(
        leading: Icon(look.icon, color: look.color),
        title: Text(look.label),
        subtitle: detail.isEmpty ? null : Text(detail),
      ),
    );
  }
}

/// Action principale collée en bas (maquette) : convertir (verrouillé tant
/// que la relecture manque), suivre une conversion en cours, puis écouter
/// (étape du lecteur).
class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.sheet,
    required this.item,
    required this.onConvert,
    required this.onOpenConversion,
    required this.onListen,
  });

  final DocumentSheet? sheet;
  final LibraryItem? item;
  final void Function(String title, int chars) onConvert;
  final ValueChanged<String> onOpenConversion;
  final void Function(String conversionId, String title) onListen;

  static const _converting = {
    'queued',
    'preparing',
    'synthesizing',
    'synthesized',
  };

  @override
  Widget build(BuildContext context) {
    final sheet = this.sheet;
    if (sheet == null || sheet.stage != DocumentStage.textReady) {
      return const SizedBox.shrink();
    }
    final conversion = item?.conversion;
    final listenable = switch (item?.status) {
      LibraryStatus.ready ||
      LibraryStatus.inProgress ||
      LibraryStatus.finished => true,
      _ => false,
    };
    final Widget action;
    if (sheet.reviewPending) {
      action = const _Pending(
        label: 'Choisir la voix et convertir',
        icon: Icons.lock_outline,
        caption: 'Après relecture',
      );
    } else if (conversion != null && _converting.contains(conversion.status)) {
      action = VoxPrimaryButton(
        label: 'Suivre la conversion',
        icon: Icons.timelapse,
        onPressed: () => onOpenConversion(conversion.id),
      );
    } else if (listenable && conversion != null) {
      action = VoxPrimaryButton(
        label: 'Écouter',
        icon: Icons.headphones,
        onPressed: () => onListen(conversion.id, sheet.title),
      );
    } else {
      action = VoxPrimaryButton(
        label: 'Choisir la voix et convertir',
        icon: Icons.graphic_eq,
        onPressed: () => onConvert(sheet.title, sheet.charCount ?? 0),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          VoxSpacing.sm,
          VoxSpacing.screenMargin,
          VoxSpacing.md,
        ),
        child: action,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.code, required this.cached});

  final String code;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    final offline = code == 'NETWORK_UNAVAILABLE' || code == 'TIMEOUT';
    if (code == 'DOCUMENT_NOT_FOUND') {
      return const VoxBanner(
        tone: VoxBannerTone.error,
        message:
            'Ce document n’existe plus (supprimé sur un autre appareil ?).',
      );
    }
    return VoxBanner(
      tone: offline ? VoxBannerTone.warning : VoxBannerTone.error,
      icon: offline ? Icons.cloud_off_outlined : null,
      message: offline
          ? (cached
                ? 'Hors ligne : fiche enregistrée sur l’appareil.'
                : 'Hors ligne : la fiche s’affichera au retour du réseau.')
          : 'Service momentanément indisponible. Tirez vers le bas pour '
                'réessayer.',
    );
  }
}
