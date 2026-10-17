import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/payment_providers.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_texts.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Le catalogue et le solde (carte du Profil, en-tête de l'historique).
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final accountUnitsProvider = FutureProvider.autoDispose(
  (ref) async => switch (await ref.read(loadOffersProvider)()) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError(error.code),
  },
);

/// Carte « Unités et offres » du Profil (ADR-0014) : solde, pass, recharge.
class UnitsCard extends ConsumerWidget {
  const UnitsCard({
    required this.onRecharge,
    this.onOpenHistory,
    super.key,
  });

  /// Vers l'historique ; `null` : la carte est déjà dans l'historique.
  final VoidCallback? onOpenHistory;

  /// Ouvre le paiement ; le solde est relu au retour.
  final Future<void> Function() onRecharge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final units = ref.watch(accountUnitsProvider);
    final balance = units.value?.balance;
    final radius = BorderRadius.circular(VoxRadius.card);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onOpenHistory,
        child: Padding(
          padding: const EdgeInsets.all(VoxSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: colors.accent),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: Text('Unités et offres', style: text.titleMedium),
                  ),
                  if (onOpenHistory != null)
                    Icon(Icons.chevron_right, color: colors.textSecondary),
                ],
              ),
              const SizedBox(height: VoxSpacing.sm),
              if (balance != null) ...[
                Text(
                  '${VoxFormat.count(balance.total)} unités restantes',
                  style: text.titleLarge,
                ),
                const SizedBox(height: VoxSpacing.xs),
                Text(
                  switch (balance.passEndsAt) {
                    final end? => 'Pass actif jusqu’au ${VoxFormat.day(end)}',
                    null => 'Sans pass en cours',
                  },
                  style: text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ] else if (units.hasError)
                Text(
                  'Solde indisponible hors connexion.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                )
              else
                const LinearProgressIndicator(),
              const SizedBox(height: VoxSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await onRecharge();
                    ref.invalidate(accountUnitsProvider);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Recharger'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filtres de l'historique.
enum UnitsFilter { all, purchases, usage }

@immutable
final class UnitsHistoryState {
  const UnitsHistoryState({
    this.entries = const [],
    this.cursor,
    this.done = false,
    this.loading = false,
    this.errorCode,
    this.filter = UnitsFilter.all,
  });

  final List<WalletEntry> entries;
  final String? cursor;

  /// Tout est chargé.
  final bool done;
  final bool loading;
  final String? errorCode;
  final UnitsFilter filter;

  List<WalletEntry> get shown => [
    for (final e in entries)
      if (switch (filter) {
        UnitsFilter.all => true,
        UnitsFilter.purchases => e.kind == WalletEntryKind.purchase,
        UnitsFilter.usage => e.kind != WalletEntryKind.purchase,
      })
        e,
  ];
}

/// L'historique, page par page.
final class UnitsHistoryController extends Notifier<UnitsHistoryState> {
  @override
  UnitsHistoryState build() => const UnitsHistoryState();

  /// Première page (ou nouvelle lecture).
  Future<void> refresh() async {
    state = UnitsHistoryState(filter: state.filter);
    await more();
  }

  /// Page suivante, si elle existe.
  Future<void> more() async {
    if (state.loading || state.done) return;
    state = UnitsHistoryState(
      entries: state.entries,
      cursor: state.cursor,
      loading: true,
      filter: state.filter,
    );
    final result = await ref.read(loadWalletPageProvider)(
      cursor: state.cursor,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(value: final page) => UnitsHistoryState(
        entries: [...state.entries, ...page.entries],
        cursor: page.nextCursor,
        done: page.nextCursor == null,
        filter: state.filter,
      ),
      Err(:final error) => UnitsHistoryState(
        entries: state.entries,
        cursor: state.cursor,
        errorCode: error.code,
        filter: state.filter,
      ),
    };
  }

  void filter(UnitsFilter filter) => state = UnitsHistoryState(
    entries: state.entries,
    cursor: state.cursor,
    done: state.done,
    loading: state.loading,
    errorCode: state.errorCode,
    filter: filter,
  );
}

// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final unitsHistoryProvider =
    NotifierProvider.autoDispose<UnitsHistoryController, UnitsHistoryState>(
      UnitsHistoryController.new,
    );

/// « Historique des unités » (maquette 08) : solde, recharge, filtres,
/// lignes par mois, pages suivantes en descendant.
class UnitsHistoryScreen extends ConsumerStatefulWidget {
  const UnitsHistoryScreen({
    required this.onRecharge,
    this.titleOf,
    super.key,
  });

  final Future<void> Function() onRecharge;

  /// Titre du livre d'une conversion (lu dans la bibliothèque).
  final String? Function(String conversionId)? titleOf;

  @override
  ConsumerState<UnitsHistoryScreen> createState() => _UnitsHistoryScreenState();
}

class _UnitsHistoryScreenState extends ConsumerState<UnitsHistoryScreen> {
  final _scroll = ScrollController();

  UnitsHistoryController get _controller =>
      ref.read(unitsHistoryProvider.notifier);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Écran pas encore rempli (rien à faire défiler) : page suivante.
  void _fillScreen() {
    if (!mounted || !_scroll.hasClients) return;
    final view = ref.read(unitsHistoryProvider);
    if (view.done || view.loading || view.errorCode != null) return;
    if (_scroll.position.maxScrollExtent < 400) unawaited(_controller.more());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.refresh());
    });
  }

  String _title(WalletEntry entry, List<Offer> offers) {
    final book = switch (entry.conversionId) {
      final id? => widget.titleOf?.call(id),
      null => null,
    };
    if (entry.isWelcomeGift) return 'Crédits offerts';
    return switch (entry.kind) {
      WalletEntryKind.purchase => switch (offers
          .where((o) => o.code == entry.offerCode)
          .firstOrNull) {
        final offer? => offerTitle(offer),
        null => 'Achat d’unités',
      },
      WalletEntryKind.consumption =>
        book == null ? 'Conversion' : 'Conversion « $book »',
      WalletEntryKind.refund =>
        book == null ? 'Remboursement' : 'Remboursement « $book »',
    };
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(unitsHistoryProvider);
    final offers = ref.watch(accountUnitsProvider).value?.offers ?? const [];
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillScreen());
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final shown = view.shown;

    // Lignes à afficher : en-têtes de mois et opérations.
    final rows = <Object>[];
    String? month;
    for (final entry in shown) {
      final local = entry.createdAt.toLocal();
      final key = VoxFormat.month(local);
      if (key != month) {
        month = key;
        rows.add(key);
      }
      rows.add(entry);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des unités')),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 400) unawaited(_controller.more());
            return false;
          },
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              VoxSpacing.screenMargin,
              VoxSpacing.sm,
              VoxSpacing.screenMargin,
              VoxSpacing.xl,
            ),
            children: [
              UnitsCard(
                onRecharge: () async {
                  await widget.onRecharge();
                  unawaited(_controller.refresh());
                },
              ),
              const SizedBox(height: VoxSpacing.md),
              Wrap(
                spacing: VoxSpacing.sm,
                children: [
                  for (final (filter, label) in const [
                    (UnitsFilter.all, 'Tout'),
                    (UnitsFilter.purchases, 'Achats'),
                    (UnitsFilter.usage, 'Consommation'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: view.filter == filter,
                      onSelected: (_) => _controller.filter(filter),
                    ),
                ],
              ),
              const SizedBox(height: VoxSpacing.md),
              if (view.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: VoxSpacing.md),
                  child: VoxBanner(
                    icon: Icons.cloud_off_outlined,
                    message: startErrorText(view.errorCode!),
                  ),
                ),
              // Le backend n'inscrit que les achats et les crédits : les
              // unités gratuites et celles du pass n'y figurent pas.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: VoxSpacing.sm),
                  Expanded(
                    child: Text(
                      'Achats et crédits seulement : les unités gratuites du '
                      'mois et celles du pass n’apparaissent pas ici.',
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VoxSpacing.md),
              if (shown.isEmpty && !view.loading && view.errorCode == null)
                Text(
                  'Aucun achat ni mouvement de crédits pour l’instant.',
                  style: text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              for (final row in rows)
                if (row is String)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      VoxSpacing.md,
                      0,
                      VoxSpacing.sm,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(
                        row.toUpperCase(),
                        style: text.labelLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else if (row is WalletEntry)
                  _EntryTile(entry: row, title: _title(row, offers)),
              if (view.loading)
                const Padding(
                  padding: EdgeInsets.all(VoxSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.title});

  final WalletEntry entry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (entry.kind) {
      WalletEntryKind.purchase => (Icons.add_card_outlined, colors.success),
      WalletEntryKind.consumption => (Icons.headphones_outlined, colors.text),
      WalletEntryKind.refund => (Icons.replay, colors.accent),
    };
    final amount =
        '${entry.units > 0 ? '+' : '−'}'
        '${VoxFormat.count(entry.units.abs())} unités';
    return Padding(
      padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
      child: MergeSemantics(
        child: Container(
          padding: const EdgeInsets.all(VoxSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(VoxRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.textSecondary),
              const SizedBox(width: VoxSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      VoxFormat.dateTime(entry.createdAt),
                      style: text.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VoxSpacing.sm),
              Text(amount, style: text.titleSmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
