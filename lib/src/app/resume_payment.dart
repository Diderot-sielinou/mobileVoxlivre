import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/payment/payment_providers.dart';

/// Au début d'une session : un paiement laissé en attente (app fermée
/// pendant la validation) rouvre le parcours sur son attente (ADR-0013).
class ResumePayment extends ConsumerStatefulWidget {
  const ResumePayment({required this.onResume, required this.child, super.key});

  final VoidCallback onResume;
  final Widget child;

  @override
  ConsumerState<ResumePayment> createState() => _ResumePaymentState();
}

class _ResumePaymentState extends ConsumerState<ResumePayment> {
  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    final pending = await ref.read(pendingPaymentProvider)();
    if (pending != null && mounted) widget.onResume();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
