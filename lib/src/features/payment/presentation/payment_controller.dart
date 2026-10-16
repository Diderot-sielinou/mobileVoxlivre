import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/payment_providers.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Rythme de relecture d'un paiement en attente (ADR-0013).
const paymentCheckEvery = Duration(seconds: 3);

/// Au-delà, on cesse de relire tout seul : « toujours en attente ».
const paymentWaitLimit = Duration(minutes: 15);

/// Étapes du parcours.
enum PaymentStep { offers, pay, waiting, done }

/// Échecs après lesquels on ne sait pas si la demande est partie : on
/// réessaie avec la même clé (pas de double débit).
bool isUncertainPaymentFailure(String code) => const {
  'NETWORK_UNAVAILABLE',
  'TIMEOUT',
  'INFRASTRUCTURE_PAYMENT_UNAVAILABLE',
  'SERVER_ERROR',
}.contains(code);

@immutable
final class PaymentViewState {
  const PaymentViewState({
    this.step = PaymentStep.offers,
    this.loading = true,
    this.loadError,
    this.offers = const [],
    this.balance,
    this.offer,
    this.phone = '',
    this.starting = false,
    this.startError,
    this.payment,
    this.stillWaiting = false,
    this.checking = false,
  });

  final PaymentStep step;
  final bool loading;

  /// Échec du chargement du catalogue.
  final String? loadError;
  final List<Offer> offers;
  final Balance? balance;

  /// L'offre choisie.
  final Offer? offer;

  /// Numéro pré-rempli (dernier qui a payé).
  final String phone;
  final bool starting;

  /// Échec du lancement (code), affiché sur l'étape « Payer ».
  final String? startError;
  final Payment? payment;

  /// Plus de 15 min d'attente : la relecture automatique s'est arrêtée.
  final bool stillWaiting;
  final bool checking;

  PaymentViewState copyWith({
    PaymentStep? step,
    bool? loading,
    String? Function()? loadError,
    List<Offer>? offers,
    Balance? balance,
    Offer? offer,
    String? phone,
    bool? starting,
    String? Function()? startError,
    Payment? payment,
    bool? stillWaiting,
    bool? checking,
  }) => PaymentViewState(
    step: step ?? this.step,
    loading: loading ?? this.loading,
    loadError: loadError == null ? this.loadError : loadError(),
    offers: offers ?? this.offers,
    balance: balance ?? this.balance,
    offer: offer ?? this.offer,
    phone: phone ?? this.phone,
    starting: starting ?? this.starting,
    startError: startError == null ? this.startError : startError(),
    payment: payment ?? this.payment,
    stillWaiting: stillWaiting ?? this.stillWaiting,
    checking: checking ?? this.checking,
  );
}

/// Le parcours de paiement (ADR-0013). Aucune règle métier ici : numéro,
/// mémoire et serveur passent par les cas d'usage.
final class PaymentController extends Notifier<PaymentViewState> {
  Timer? _poll;
  DateTime? _waitingSince;

  /// Clé de la tentative en cours, et ce qu'elle couvre.
  String? _key;
  ({String offer, String phone})? _keyFor;

  @override
  PaymentViewState build() {
    ref.onDispose(() => _poll?.cancel());
    return const PaymentViewState();
  }

  /// Ouvre le parcours : sur l'attente d'un paiement laissé en cours, sinon
  /// sur les offres.
  Future<void> open() async {
    final pending = ref.read(pendingPaymentProvider);
    final (pendingId, phone) = await (pending(), pending.lastPhone()).wait;
    if (!ref.mounted) return;
    state = state.copyWith(phone: phone ?? '');
    if (pendingId != null) {
      state = state.copyWith(step: PaymentStep.waiting, loading: false);
      await _resume(pendingId);
      return;
    }
    await loadOffers();
  }

  Future<void> loadOffers() async {
    state = state.copyWith(loading: true, loadError: () => null);
    final result = await ref.read(loadOffersProvider)();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        loading: false,
        offers: value.offers,
        balance: value.balance,
      ),
      Err(:final error) => state.copyWith(
        loading: false,
        loadError: () => error.code,
      ),
    };
  }

  void choose(Offer offer) => state = state.copyWith(
    step: PaymentStep.pay,
    offer: offer,
    startError: () => null,
  );

  /// Revient d'une étape ; `false` s'il n'y a plus rien avant (on quitte).
  bool back() {
    switch (state.step) {
      case PaymentStep.pay:
        state = state.copyWith(step: PaymentStep.offers);
        if (state.offers.isEmpty) unawaited(loadOffers());
        return true;
      case PaymentStep.offers || PaymentStep.waiting || PaymentStep.done:
        return false;
    }
  }

  Future<void> pay(String phone) async {
    final offer = state.offer;
    if (offer == null || state.starting) return;
    // Même offre, même numéro : même tentative (même clé).
    final scope = (offer: offer.code, phone: phone.trim());
    if (_key == null || _keyFor != scope) {
      _key = ref.read(keyGeneratorProvider).newKey();
      _keyFor = scope;
    }
    state = state.copyWith(starting: true, startError: () => null);
    final result = await ref.read(startPaymentProvider)(
      offerCode: offer.code,
      phone: phone,
      idempotencyKey: _key!,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final payment):
        state = state.copyWith(starting: false, phone: phone);
        _show(payment);
      case Err(:final error) when error.code == 'PAYMENT_IN_PROGRESS_CONFLICT':
        // Un paiement attend déjà : on le reprend s'il est connu ici.
        state = state.copyWith(starting: false);
        final pendingId = await ref.read(pendingPaymentProvider)();
        if (!ref.mounted) return;
        if (pendingId != null) {
          await _resume(pendingId);
        } else {
          state = state.copyWith(startError: () => error.code);
        }
      case Err(:final error):
        // Refus net : la prochaine tentative aura une nouvelle clé.
        if (!isUncertainPaymentFailure(error.code)) _key = null;
        state = state.copyWith(starting: false, startError: () => error.code);
    }
  }

  /// « J'ai déjà validé », ou « Vérifier » après 15 min.
  Future<void> check() async {
    final payment = state.payment;
    if (payment == null || state.checking) return;
    state = state.copyWith(checking: true);
    await _check(payment.id);
    if (ref.mounted) state = state.copyWith(checking: false);
  }

  /// Après un échec : même offre, nouvelle tentative.
  void retry() {
    _key = null;
    state = state.copyWith(step: PaymentStep.pay, startError: () => null);
  }

  Future<void> _resume(String paymentId) async {
    state = state.copyWith(step: PaymentStep.waiting, loading: false);
    final result = await ref.read(checkPaymentProvider)(paymentId);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final payment):
        _show(payment);
      case Err():
        // Paiement oublié ou réseau absent : retour aux offres.
        state = state.copyWith(step: PaymentStep.offers);
        await loadOffers();
    }
  }

  /// Affiche [payment] : attente (relecture) ou résultat.
  void _show(Payment payment) {
    if (payment.status.isFinal) {
      _poll?.cancel();
      state = state.copyWith(step: PaymentStep.done, payment: payment);
      if (payment.status == PaymentStatus.succeeded) {
        unawaited(_refreshBalance());
      }
      return;
    }
    state = state.copyWith(
      step: PaymentStep.waiting,
      payment: payment,
      stillWaiting: false,
    );
    _waitingSince ??= ref.read(clockProvider).now();
    _poll?.cancel();
    _poll = Timer.periodic(paymentCheckEvery, (_) {
      final waited = ref.read(clockProvider).now().difference(_waitingSince!);
      if (waited >= paymentWaitLimit) {
        _poll?.cancel();
        state = state.copyWith(stillWaiting: true);
        return;
      }
      unawaited(_check(payment.id));
    });
  }

  Future<void> _check(String paymentId) async {
    final result = await ref.read(checkPaymentProvider)(paymentId);
    if (!ref.mounted) return;
    // Réseau absent : on réessaiera au prochain tour.
    if (result case Ok(value: final payment)) {
      if (payment.status.isFinal) {
        _show(payment);
      } else {
        state = state.copyWith(payment: payment);
      }
    }
  }

  /// Après un succès : validité du pass, solde à jour.
  Future<void> _refreshBalance() async {
    final result = await ref.read(loadOffersProvider)();
    if (!ref.mounted) return;
    if (result case Ok(:final value)) {
      state = state.copyWith(offers: value.offers, balance: value.balance);
    }
  }
}

// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final paymentControllerProvider =
    NotifierProvider.autoDispose<PaymentController, PaymentViewState>(
      PaymentController.new,
    );
