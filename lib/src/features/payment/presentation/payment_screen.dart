import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_controller.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_texts.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Le parcours de paiement Mobile Money (ADR-0013) : offres → payer →
/// validation sur le téléphone → réussi / non abouti. [onClose] rend
/// `true` si des unités ont été ajoutées.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.onClose, super.key});

  final ValueChanged<bool> onClose;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentController get _controller =>
      ref.read(paymentControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open());
    });
  }

  void _close() {
    final payment = ref.read(paymentControllerProvider).payment;
    widget.onClose(payment?.status == PaymentStatus.succeeded);
  }

  /// Retour : étape précédente, sinon on quitte.
  void _back() {
    if (!_controller.back()) _close();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(paymentControllerProvider);
    final title = switch (view.step) {
      PaymentStep.offers => 'Recharger des unités',
      PaymentStep.pay => 'Paiement Mobile Money',
      PaymentStep.waiting => 'Validation sur le téléphone',
      PaymentStep.done => 'Paiement',
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(title),
          actions: [
            IconButton(
              tooltip: 'Fermer',
              onPressed: _close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          child: switch (view.step) {
            PaymentStep.offers => _OffersStep(
              view: view,
              onChoose: _controller.choose,
              onRetry: _controller.loadOffers,
            ),
            PaymentStep.pay => _PayStep(
              view: view,
              onPay: _controller.pay,
            ),
            PaymentStep.waiting => _WaitingStep(
              view: view,
              onCheck: _controller.check,
              onClose: _close,
            ),
            PaymentStep.done => _DoneStep(
              view: view,
              onRetry: _controller.retry,
              onClose: _close,
            ),
          },
        ),
      ),
    );
  }
}

/// Le détail du solde, par source.
String balanceDetail(Balance balance) {
  final free = VoxFormat.count(balance.freeRemaining);
  final parts = ['$free gratuites ce mois (voix standard)'];
  if (balance.passEndsAt case final end?) {
    final pass = VoxFormat.count(balance.passRemaining);
    parts.add('$pass du pass, jusqu’au ${VoxFormat.day(end)}');
  }
  parts.add('${VoxFormat.count(balance.credits)} en crédits');
  return parts.join(' · ');
}

/// Une carte de contenu.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VoxSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VoxRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

const _padding = EdgeInsets.fromLTRB(
  VoxSpacing.screenMargin,
  VoxSpacing.sm,
  VoxSpacing.screenMargin,
  VoxSpacing.xl,
);

class _OffersStep extends StatelessWidget {
  const _OffersStep({
    required this.view,
    required this.onChoose,
    required this.onRetry,
  });

  final PaymentViewState view;
  final ValueChanged<Offer> onChoose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    if (view.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (view.loadError case final code?) {
      return ListView(
        padding: _padding,
        children: [
          VoxBanner(
            tone: VoxBannerTone.error,
            icon: Icons.cloud_off_outlined,
            message: startErrorText(code),
          ),
          const SizedBox(height: VoxSpacing.md),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    }
    final balance = view.balance;
    return ListView(
      padding: _padding,
      children: [
        if (balance != null)
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre solde', style: text.labelLarge),
                const SizedBox(height: VoxSpacing.xs),
                Text(
                  '${VoxFormat.count(balance.total)} unités',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: VoxSpacing.xs),
                Text(
                  balanceDetail(balance),
                  style: text.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        const SizedBox(height: VoxSpacing.lg),
        Text('Choisissez une offre', style: text.titleMedium),
        const SizedBox(height: VoxSpacing.sm),
        for (final offer in view.offers)
          Padding(
            padding: const EdgeInsets.only(bottom: VoxSpacing.sm),
            child: Material(
              color: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VoxRadius.card),
                side: BorderSide(color: colors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(VoxRadius.card),
                onTap: () => onChoose(offer),
                child: Padding(
                  padding: const EdgeInsets.all(VoxSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        offer.kind == OfferKind.pass
                            ? Icons.event_available_outlined
                            : Icons.bolt,
                        color: colors.accent,
                      ),
                      const SizedBox(width: VoxSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(offerTitle(offer), style: text.titleSmall),
                            Text(
                              offerDetail(offer),
                              style: text.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: VoxSpacing.sm),
                      Text(
                        VoxFormat.xaf(offer.priceXaf),
                        style: text.titleSmall?.copyWith(color: colors.accent),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: VoxSpacing.sm),
        Text(
          'Les voix naturelles comptent 4 unités par caractère, les voix '
          'standard 1.',
          style: text.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _PayStep extends StatefulWidget {
  const _PayStep({required this.view, required this.onPay});

  final PaymentViewState view;
  final ValueChanged<String> onPay;

  @override
  State<_PayStep> createState() => _PayStepState();
}

class _PayStepState extends State<_PayStep> {
  late final _phone = TextEditingController(
    text: _local(widget.view.phone),
  );

  /// « +237694821033 » → « 694821033 » (l'indicatif est affiché à côté).
  static String _local(String phone) =>
      phone.startsWith('+237') ? phone.substring(4) : phone;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() => widget.onPay(_phone.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final offer = widget.view.offer!;
    final error = widget.view.startError;
    return ListView(
      padding: _padding,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offerTitle(offer), style: text.titleMedium),
              const SizedBox(height: VoxSpacing.xs),
              Text(
                VoxFormat.xaf(offer.priceXaf),
                style: text.headlineMedium?.copyWith(color: colors.accent),
              ),
              Text(
                '${VoxFormat.count(offer.units)} unités · '
                '${offerDetail(offer)}',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: VoxSpacing.lg),
        Text('Numéro qui paie', style: text.titleSmall),
        const SizedBox(height: VoxSpacing.sm),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9 +]')),
            LengthLimitingTextInputFormatter(16),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            prefixText: '+237 ',
            hintText: '6 94 82 10 33',
            labelText: 'Orange Money ou MTN MoMo',
            errorText: error == 'INVALID_PAYMENT_PHONE'
                ? startErrorText(error!)
                : null,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: VoxSpacing.xs),
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
            const SizedBox(width: VoxSpacing.xs),
            Expanded(
              child: Text(
                'Le numéro peut être différent de celui de votre compte.',
                style: text.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
          ],
        ),
        if (error != null && error != 'INVALID_PAYMENT_PHONE') ...[
          const SizedBox(height: VoxSpacing.md),
          VoxBanner(
            tone: error == 'PAYMENT_IN_PROGRESS_CONFLICT'
                ? VoxBannerTone.warning
                : VoxBannerTone.error,
            message: startErrorText(error),
          ),
        ],
        const SizedBox(height: VoxSpacing.lg),
        VoxPrimaryButton(
          label: 'Payer ${VoxFormat.xaf(offer.priceXaf)}',
          icon: Icons.lock_outline,
          loading: widget.view.starting,
          onPressed: _submit,
        ),
        const SizedBox(height: VoxSpacing.lg),
        _Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined, color: colors.accent),
              const SizedBox(width: VoxSpacing.sm),
              Expanded(
                child: Text(
                  'Aucun prélèvement automatique : vous validez sur votre '
                  'téléphone avec votre code secret.',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaitingStep extends StatelessWidget {
  const _WaitingStep({
    required this.view,
    required this.onCheck,
    required this.onClose,
  });

  final PaymentViewState view;
  final VoidCallback onCheck;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final payment = view.payment;
    return ListView(
      padding: _padding,
      children: [
        Row(
          children: [
            Icon(Icons.phonelink_ring_outlined, color: colors.accent),
            const SizedBox(width: VoxSpacing.sm),
            Text(
              'Action requise',
              style: text.labelLarge?.copyWith(color: colors.accent),
            ),
          ],
        ),
        const SizedBox(height: VoxSpacing.sm),
        Semantics(
          header: true,
          child: Text(
            'Validez le paiement sur votre téléphone',
            style: text.headlineSmall,
          ),
        ),
        if (payment != null) ...[
          const SizedBox(height: VoxSpacing.sm),
          Text(
            'Une demande de ${VoxFormat.xaf(payment.amountXaf)} arrive sur '
            'le ${maskedPhone(payment.phoneSuffix)}.',
            style: text.bodyLarge,
          ),
        ],
        const SizedBox(height: VoxSpacing.lg),
        _Panel(
          child: Column(
            children: [
              const _Step(
                number: 1,
                title: 'Ouvrez l’invite de l’opérateur',
                detail:
                    'Elle s’affiche toute seule ; sinon composez *150# '
                    '(Orange) ou *126# (MTN).',
              ),
              const Divider(height: VoxSpacing.lg),
              _Step(
                number: 2,
                title: 'Saisissez votre code secret',
                detail: payment == null
                    ? 'Il autorise le débit.'
                    : 'Il autorise le débit de '
                          '${VoxFormat.xaf(payment.amountXaf)}.',
              ),
            ],
          ),
        ),
        const SizedBox(height: VoxSpacing.md),
        // Annoncé quand l'état change, sans prendre le focus.
        Semantics(
          liveRegion: true,
          container: true,
          child: view.stillWaiting
              ? const VoxBanner(
                  icon: Icons.hourglass_bottom,
                  message:
                      'Toujours en attente. Si vous avez validé, '
                      'vérifiez ; sinon rien ne sera débité.',
                )
              : Row(
                  children: [
                    Icon(
                      Icons.hourglass_top,
                      size: 20,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: VoxSpacing.sm),
                    Expanded(
                      child: Text(
                        'En attente de votre validation…',
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: VoxSpacing.lg),
        OutlinedButton.icon(
          onPressed: view.checking ? null : onCheck,
          icon: const Icon(Icons.refresh),
          label: Text(view.stillWaiting ? 'Vérifier' : 'J’ai déjà validé'),
        ),
        const SizedBox(height: VoxSpacing.sm),
        TextButton(onPressed: onClose, child: const Text('Fermer')),
        Text(
          'Vous pouvez fermer : le paiement continue, et le résultat '
          's’affichera à votre retour.',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.detail,
  });

  final int number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.elevated,
            child: Text('$number', style: text.labelLarge),
          ),
          const SizedBox(width: VoxSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                Text(detail, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({
    required this.view,
    required this.onRetry,
    required this.onClose,
  });

  final PaymentViewState view;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final payment = view.payment!;
    final succeeded = payment.status == PaymentStatus.succeeded;
    final offer = view.offers
        .where((o) => o.code == payment.offerCode)
        .firstOrNull;
    final failure = succeeded ? null : failureText(payment);
    final balance = view.balance;
    return ListView(
      padding: _padding,
      children: [
        const SizedBox(height: VoxSpacing.md),
        Icon(
          succeeded ? Icons.check_circle_outline : Icons.error_outline,
          size: 72,
          color: succeeded ? colors.success : colors.error,
        ),
        const SizedBox(height: VoxSpacing.md),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            succeeded ? 'Paiement réussi !' : failure!.title,
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
        ),
        const SizedBox(height: VoxSpacing.sm),
        if (succeeded) ...[
          if (offer != null)
            Text(
              '+${VoxFormat.count(offer.units)} unités ajoutées',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: colors.accent),
            ),
          if (offer?.kind == OfferKind.pass) ...[
            if (balance?.nextPassStartsAt case final start?)
              Text(
                'Votre nouveau pass commence le ${VoxFormat.day(start)}.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              )
            else if (balance?.passEndsAt case final end?)
              Text(
                'Valable jusqu’au ${VoxFormat.day(end)}.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
          ],
        ] else
          Text(
            failure!.detail,
            textAlign: TextAlign.center,
            style: text.bodyLarge,
          ),
        const SizedBox(height: VoxSpacing.lg),
        _Panel(
          child: Column(
            children: [
              _Line('Montant', VoxFormat.xaf(payment.amountXaf)),
              _Line('Numéro', maskedPhone(payment.phoneSuffix)),
              _Line('Référence', paymentReference(payment)),
              _Line(
                'Date',
                VoxFormat.dateTime(payment.completedAt ?? payment.createdAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: VoxSpacing.lg),
        if (succeeded)
          VoxPrimaryButton(
            label: 'Continuer',
            icon: Icons.arrow_forward,
            onPressed: onClose,
          )
        else ...[
          if (payment.status != PaymentStatus.amountMismatch) ...[
            VoxPrimaryButton(
              label: 'Réessayer le paiement',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
            const SizedBox(height: VoxSpacing.sm),
          ],
          OutlinedButton(onPressed: onClose, child: const Text('Fermer')),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VoxSpacing.xs),
      child: MergeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(
                  color: context.vox.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: VoxSpacing.sm),
            Flexible(
              child: Text(
                value,
                style: text.titleSmall,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
