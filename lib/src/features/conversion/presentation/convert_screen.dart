import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';
import 'package:voxlivre/src/features/conversion/presentation/convert_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Message d'un refus de lancement, par code.
String startErrorText(String code) => switch (code) {
  'DOCUMENT_REVIEW_REQUIRED' =>
    'Relisez d’abord le texte : certaines pages ont été mal reconnues.',
  'DOCUMENT_TEXT_NOT_READY' => 'Le texte n’est pas encore prêt.',
  'QUOTA_CONVERSION_LIMIT_EXCEEDED' =>
    'Ce document est trop long pour une seule conversion.',
  'INVALID_VOICE' =>
    'Cette voix n’est plus disponible. Choisissez-en une '
        'autre.',
  'INVALID_CONVERSION_TEXT' => 'Le texte de ce document ne peut pas être lu.',
  'NETWORK_UNAVAILABLE' ||
  'TIMEOUT' => 'Pas de connexion. Réessayez quand le réseau revient.',
  _ => 'Le service est momentanément indisponible. Réessayez.',
};

String _units(int value) => '${VoxFormat.count(value)} unités';

String tierLabel(VoiceTier tier) => switch (tier) {
  VoiceTier.standard => 'Standard',
  VoiceTier.natural => 'Naturelle',
};

/// Choisir la voix et convertir (maquette « Paramètres voix ») : coût de
/// chaque voix calculé, solde utilisable, manque d'unités expliqué
/// (ADR-0008). [onStarted] reçoit la conversion lancée.
class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({
    required this.documentId,
    required this.title,
    required this.chars,
    required this.onStarted,
    super.key,
  });

  final String documentId;
  final String title;
  final int chars;
  final ValueChanged<String> onStarted;

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  ConvertController get _controller =>
      ref.read(convertControllerProvider(widget.documentId).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.load());
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(convertControllerProvider(widget.documentId), (_, next) {
      if (next.conversionId case final id?) widget.onStarted(id);
    });
    final view = ref.watch(convertControllerProvider(widget.documentId));
    final options = view.options;
    final account = options?.account;
    final voice = view.voice;
    final chars = widget.chars;

    // Le refus du backend fait foi ; sinon, le calcul local.
    final missing =
        view.quota?.missing ??
        (account != null && voice != null
            ? account.shortfall(chars, voice.tier)
            : 0);
    final tooLong = account?.tooLong(chars) ?? false;
    final canStart =
        voice != null && missing == 0 && !tooLong && !view.starting;

    return Scaffold(
      appBar: AppBar(title: const Text('Choisir la voix')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VoxSpacing.screenMargin,
          VoxSpacing.sm,
          VoxSpacing.screenMargin,
          VoxSpacing.xl,
        ),
        children: [
          _DocumentLine(title: widget.title, chars: chars),
          const SizedBox(height: VoxSpacing.md),
          if (view.loading && options == null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: VoxSpacing.sm),
            const Text('Chargement des voix…', textAlign: TextAlign.center),
          ],
          if (options == null && view.errorCode != null && !view.loading) ...[
            VoxBanner(
              tone: VoxBannerTone.error,
              message: startErrorText(view.errorCode!),
            ),
            const SizedBox(height: VoxSpacing.sm),
            OutlinedButton.icon(
              onPressed: _controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
          if (account != null && voice != null) ...[
            _Balance(account: account, voice: voice),
            const SizedBox(height: VoxSpacing.md),
            if (tooLong) ...[
              VoxBanner(
                tone: VoxBannerTone.error,
                message:
                    'Ce document dépasse '
                    '${VoxFormat.count(account.maxCharsPerConversion)} '
                    'caractères par conversion. Découpez le PDF.',
              ),
              const SizedBox(height: VoxSpacing.md),
            ] else if (missing > 0) ...[
              _Shortfall(
                missing: missing,
                usable: view.quota?.usable ?? account.usableFor(voice.tier),
                required:
                    view.quota?.requested ?? account.costFor(chars, voice.tier),
                voice: voice,
                standard: _cheaperStandard(
                  options!.voices,
                  account,
                  chars,
                  voice,
                ),
                onChoose: _controller.choose,
              ),
              const SizedBox(height: VoxSpacing.md),
            ],
            if (view.errorCode != null &&
                view.errorCode != 'QUOTA_EXCEEDED') ...[
              VoxBanner(
                tone: VoxBannerTone.error,
                message: startErrorText(view.errorCode!),
              ),
              const SizedBox(height: VoxSpacing.md),
            ],
            Semantics(
              header: true,
              child: Text(
                'Voix disponibles',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: VoxSpacing.sm),
            for (final v in options!.voices) ...[
              _VoiceCard(
                voice: v,
                cost: account.costFor(chars, v.tier),
                missing: account.shortfall(chars, v.tier) > 0,
                selected: v.id == voice.id,
                onTap: () => _controller.choose(v.id),
              ),
              const SizedBox(height: VoxSpacing.sm),
            ],
          ],
        ],
      ),
      bottomNavigationBar: voice == null || account == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VoxSpacing.screenMargin,
                  VoxSpacing.sm,
                  VoxSpacing.screenMargin,
                  VoxSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VoxPrimaryButton(
                      label: 'Convertir',
                      icon: Icons.graphic_eq,
                      loading: view.starting,
                      onPressed: canStart ? _controller.start : null,
                    ),
                    const SizedBox(height: VoxSpacing.xs),
                    Text(
                      // Le nom de la voix ici : les vrais libellés sont
                      // trop longs pour le bouton.
                      missing > 0 || tooLong
                          ? 'Aucune unité n’a été décomptée.'
                          : '${voice.label} · '
                                '${_units(account.costFor(chars, voice.tier))} '
                                'seront décomptées.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Une voix standard qui suffirait, quand la voix choisie est trop chère.
  static Voice? _cheaperStandard(
    List<Voice> voices,
    UnitsAccount account,
    int chars,
    Voice chosen,
  ) {
    if (chosen.tier == VoiceTier.standard) return null;
    return voices
        .where(
          (v) =>
              v.tier == VoiceTier.standard &&
              account.shortfall(chars, v.tier) == 0,
        )
        .firstOrNull;
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.title, required this.chars});

  final String title;
  final int chars;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.description_outlined, color: context.vox.accent),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${VoxFormat.count(chars)} caractères',
          style: text.bodySmall,
        ),
      ),
    );
  }
}

/// Solde utilisable pour la gamme choisie, et son détail par source.
class _Balance extends StatelessWidget {
  const _Balance({required this.account, required this.voice});

  final UnitsAccount account;
  final Voice voice;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final free = VoxFormat.count(account.freeRemaining);
    final onlyStandard = voice.tier == VoiceTier.natural
        ? ' (voix standard seulement)'
        : '';
    final parts = [
      'Gratuit ce mois : $free$onlyStandard',
      if (account.passRemaining > 0)
        'Pass : ${VoxFormat.count(account.passRemaining)}',
      if (account.credits > 0) 'Crédits : ${VoxFormat.count(account.credits)}',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VoxSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: colors.accent),
            const SizedBox(width: VoxSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Utilisable pour cette voix : '
                    '${_units(account.usableFor(voice.tier))}',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: VoxSpacing.xs),
                  Text(parts.join(' · '), style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Solde insuffisant » (maquette) : chiffres, voix standard qui suffit,
/// recharge à venir.
class _Shortfall extends StatelessWidget {
  const _Shortfall({
    required this.missing,
    required this.usable,
    required this.required,
    required this.voice,
    required this.standard,
    required this.onChoose,
  });

  final int missing;
  final int usable;
  final int required;
  final Voice voice;
  final Voice? standard;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final standard = this.standard;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VoxSpacing.md),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(VoxRadius.card),
          border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.warning),
                const SizedBox(width: VoxSpacing.sm),
                Expanded(
                  child: Text(
                    'Il vous manque ${_units(missing)} pour la voix '
                    '${voice.label}.',
                    style: text.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VoxSpacing.sm),
            _Figure(label: 'Utilisable', value: _units(usable)),
            _Figure(label: 'Requis', value: _units(required)),
            _Figure(
              label: 'Manquant',
              value: '−${_units(missing)}',
              color: colors.warning,
            ),
            if (standard != null) ...[
              const SizedBox(height: VoxSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => onChoose(standard.id),
                icon: const Icon(Icons.swap_horiz),
                label: Text('Passer en voix standard (${standard.label})'),
              ),
            ],
            const SizedBox(height: VoxSpacing.sm),
            const VoxPrimaryButton(
              label: 'Recharger des unités',
              icon: Icons.bolt,
              onPressed: null,
            ),
            const SizedBox(height: VoxSpacing.xs),
            Text(
              'Disponible à l’étape paiement (Mobile Money).',
              textAlign: TextAlign.center,
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Flexible(
            child: Text(value, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Une voix : libellé, gamme (texte), coût, choix.
class _VoiceCard extends StatelessWidget {
  const _VoiceCard({
    required this.voice,
    required this.cost,
    required this.missing,
    required this.selected,
    required this.onTap,
  });

  final Voice voice;
  final int cost;
  final bool missing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final weight = voice.tier == VoiceTier.natural ? '×4' : '×1';
    return Semantics(
      selected: selected,
      button: true,
      label:
          '${voice.label}, voix ${tierLabel(voice.tier).toLowerCase()}, '
          '${_units(cost)}${missing ? ', unités insuffisantes' : ''}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoxRadius.card),
          side: BorderSide(
            color: selected ? colors.accent : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VoxSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? colors.accent : colors.textSecondary,
                ),
                const SizedBox(width: VoxSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voice.label, style: text.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${tierLabel(voice.tier)} $weight · ${_units(cost)}',
                        style: text.bodySmall,
                      ),
                      if (missing)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: colors.warning,
                              ),
                              const SizedBox(width: VoxSpacing.xs),
                              Flexible(
                                child: Text(
                                  'Unités insuffisantes',
                                  style: text.labelSmall?.copyWith(
                                    color: colors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
