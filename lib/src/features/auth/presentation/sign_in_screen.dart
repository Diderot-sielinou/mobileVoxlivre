import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_messages.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_routes.dart';
import 'package:voxlivre/src/features/auth/presentation/sign_in_controller.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';
import 'package:voxlivre/src/shared/design/vox_tokens.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_banner.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_primary_button.dart';

/// Connexion, étape 1 : numéro mobile ou adresse e-mail.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phone = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(signInControllerProvider.notifier);
    final input = switch (ref.read(signInControllerProvider).method) {
      SignInMethod.phone => _phone.text,
      SignInMethod.email => _email.text,
    };
    if (await controller.sendCode(input) && mounted) {
      await context.push(AuthRoutes.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInControllerProvider);
    final controller = ref.read(signInControllerProvider.notifier);
    final text = Theme.of(context).textTheme;
    final colors = context.vox;
    final error = state.errorCode;
    final fieldError = error != null && fieldErrorCodes.contains(error)
        ? authMessage(error)
        : null;
    final screenError = error != null && !fieldErrorCodes.contains(error)
        ? error
        : null;
    final swap = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : VoxMotion.swap;

    return Scaffold(
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: VoxSpacing.screenMargin,
              vertical: VoxSpacing.lg,
            ),
            children: [
              const _Wordmark(),
              const SizedBox(height: VoxSpacing.xl),
              Text('Bienvenue sur Voxlivre', style: text.headlineLarge),
              const SizedBox(height: VoxSpacing.sm),
              Text(
                'Connectez-vous pour retrouver vos livres et votre '
                'progression sur tous vos appareils.',
                style: text.bodyLarge?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: VoxSpacing.lg),
              AnimatedSwitcher(
                duration: swap,
                child: screenError == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: VoxSpacing.md),
                        child: VoxBanner(
                          message: authMessage(screenError),
                          tone: rateLimitCodes.contains(screenError)
                              ? VoxBannerTone.warning
                              : VoxBannerTone.error,
                        ),
                      ),
              ),
              SegmentedButton<SignInMethod>(
                segments: const [
                  ButtonSegment(
                    value: SignInMethod.phone,
                    icon: Icon(Icons.smartphone_outlined),
                    label: Text('Téléphone'),
                  ),
                  ButtonSegment(
                    value: SignInMethod.email,
                    icon: Icon(Icons.mail_outline),
                    label: Text('E-mail'),
                  ),
                ],
                selected: {state.method},
                showSelectedIcon: false,
                onSelectionChanged: state.busy
                    ? null
                    : (selection) => controller.selectMethod(selection.first),
              ),
              const SizedBox(height: VoxSpacing.lg),
              AnimatedSwitcher(
                duration: swap,
                child: switch (state.method) {
                  SignInMethod.phone => _PhoneField(
                    key: const ValueKey(SignInMethod.phone),
                    controller: _phone,
                    error: fieldError,
                    onSubmitted: _submit,
                  ),
                  SignInMethod.email => _EmailField(
                    key: const ValueKey(SignInMethod.email),
                    controller: _email,
                    error: fieldError,
                    onSubmitted: _submit,
                  ),
                },
              ),
              const SizedBox(height: VoxSpacing.lg),
              VoxPrimaryButton(
                label: 'Recevoir un code',
                icon: Icons.arrow_forward,
                loading: state.busy,
                onPressed: _submit,
              ),
              const SizedBox(height: VoxSpacing.xl),
              Text(
                'En continuant, vous acceptez les conditions d’utilisation '
                'et la politique de confidentialité de Voxlivre.',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « Voxlivre », « livre » en ambre comme sur le splash.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge;
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Vox'),
            TextSpan(
              text: 'livre',
              style: TextStyle(color: context.vox.accent),
            ),
          ],
        ),
        style: style,
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.error,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
        LengthLimitingTextInputFormatter(13),
      ],
      onSubmitted: (_) => onSubmitted(),
      style: text.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Numéro mobile',
        hintText: '6 99 00 00 00',
        helperText: 'Orange ou MTN, 9 chiffres commençant par 6',
        helperMaxLines: 2,
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: VoxSpacing.md,
            right: VoxSpacing.sm,
          ),
          child: Semantics(
            label: 'Indicatif du Cameroun',
            child: Text('+237', style: text.labelLarge),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.error,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.send,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => onSubmitted(),
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Adresse e-mail',
        hintText: 'nom@mail.com',
        helperText: 'Adresse personnelle ou universitaire',
        errorText: error,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.alternate_email),
      ),
    );
  }
}
