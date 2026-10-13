import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_messages.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_routes.dart';
import 'package:voxlivre/src/features/auth/presentation/sign_in_controller.dart';
import 'package:voxlivre/src/features/auth/presentation/widgets/code_input.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/vox_typography.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Durée de validité d'un code (backend : `OTP_EXPIRES_IN_SECONDS`).
const codeLifetime = Duration(minutes: 5);

/// Attente avant de pouvoir redemander un code (le backend en accepte 5
/// par tranche de 10 minutes).
const resendDelay = Duration(seconds: 30);

/// Connexion, étape 2 : le code reçu.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key});

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _code = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Une seconde suffit : les comptes à rebours s'affichent à la seconde.
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) _code.text = digits.substring(0, 6);
  }

  void _edit() {
    ref.read(signInControllerProvider.notifier).editTarget();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AuthRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final target = state.target;
    final sentAt = state.codeSentAt;
    if (target == null || sentAt == null) {
      // Ouvert sans code envoyé (retour système, redémarrage) : saisie.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AuthRoutes.signIn);
      });
      return const Scaffold();
    }

    final text = Theme.of(context).textTheme;
    final colors = context.vox;
    final elapsed = ref.read(clockProvider).now().difference(sentAt);
    final expiresIn = codeLifetime - elapsed;
    final resendIn = resendDelay - elapsed;
    final error = state.errorCode;
    final isPhone = target is PhoneTarget;
    const tabular = TextStyle(fontFeatures: VoxTypography.tabularFigures);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        leading: BackButton(onPressed: _edit),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: VoxSpacing.screenMargin,
            vertical: VoxSpacing.md,
          ),
          children: [
            if (error != null && rateLimitCodes.contains(error)) ...[
              VoxBanner(message: authMessage(error)),
              const SizedBox(height: VoxSpacing.lg),
            ],
            Text('Entrez le code reçu', style: text.headlineLarge),
            const SizedBox(height: VoxSpacing.sm),
            Text.rich(
              TextSpan(
                text: isPhone
                    ? 'Code envoyé par SMS au '
                    : 'Code envoyé par e-mail à ',
                children: [
                  TextSpan(
                    text: target.masked,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              style: text.bodyLarge?.copyWith(color: colors.textSecondary),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: state.busy ? null : _edit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: Text(
                  isPhone ? 'Modifier le numéro' : 'Modifier l’adresse',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accent,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: VoxSpacing.md),
            CodeInput(
              controller: _code,
              enabled: !state.busy && expiresIn > Duration.zero,
              hasError: error != null && fieldErrorCodes.contains(error),
              rejections: state.rejections,
              onCompleted: controller.verify,
            ),
            const SizedBox(height: VoxSpacing.md),
            _Status(
              busy: state.busy,
              // Limitation : déjà dans le bandeau du haut.
              error: error != null && !rateLimitCodes.contains(error)
                  ? authMessage(error)
                  : null,
            ),
            Center(
              child: ActionChip(
                avatar: Icon(Icons.content_paste, color: colors.accent),
                label: const Text('Coller le code'),
                onPressed: state.busy ? null : _paste,
              ),
            ),
            const SizedBox(height: VoxSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 20, color: colors.textSecondary),
                const SizedBox(width: VoxSpacing.sm),
                Flexible(
                  child: Text.rich(
                    expiresIn > Duration.zero
                        ? TextSpan(
                            text: 'Le code expire dans ',
                            children: [
                              TextSpan(
                                text: _clock(expiresIn),
                                style: tabular.copyWith(
                                  color: colors.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const TextSpan(
                            text: 'Le code a expiré. Demandez-en un nouveau.',
                          ),
                    style: text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VoxSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: state.busy || resendIn > Duration.zero
                    ? null
                    : () {
                        _code.clear();
                        controller.resend();
                      },
                icon: const Icon(Icons.refresh),
                label: resendIn > Duration.zero
                    ? Text.rich(
                        TextSpan(
                          text: 'Renvoyer le code dans ',
                          children: [
                            TextSpan(text: _clock(resendIn), style: tabular),
                          ],
                        ),
                      )
                    : const Text('Renvoyer le code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `4:07` : minutes, puis secondes sur deux chiffres (arrondi au-dessus).
  static String _clock(Duration d) {
    final seconds = (d.inMilliseconds / 1000).ceil();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// Sous les cases : vérification en cours, ou erreur (icône + texte).
class _Status extends StatelessWidget {
  const _Status({required this.busy, required this.error});

  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.vox;
    final text = Theme.of(context).textTheme;
    final Widget child;
    if (busy) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: VoxSpacing.sm),
          Text('Vérification du code…', style: text.bodyMedium),
        ],
      );
    } else if (error != null) {
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 20),
          const SizedBox(width: VoxSpacing.sm),
          Expanded(
            child: Text(
              error!,
              style: text.bodyMedium?.copyWith(color: colors.error),
            ),
          ),
        ],
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: VoxSpacing.md),
        child: child,
      ),
    );
  }
}
