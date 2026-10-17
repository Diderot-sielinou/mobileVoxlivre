import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/auth/domain/email_address.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';
import 'package:voxlivre/src/features/auth/domain/phone_number.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Moyen de recevoir le code.
enum SignInMethod { phone, email }

/// État du parcours de connexion (écran de saisie puis écran du code).
@immutable
final class SignInState {
  const SignInState({
    this.method = SignInMethod.phone,
    this.target,
    this.codeSentAt,
    this.busy = false,
    this.errorCode,
    this.rejections = 0,
  });

  final SignInMethod method;

  /// Destination du dernier code envoyé ; `null` avant l'envoi.
  final SignInTarget? target;
  final DateTime? codeSentAt;

  /// Un appel est en cours.
  final bool busy;

  /// Code du dernier échec, effacé à l'action suivante.
  final String? errorCode;

  /// Nombre de codes refusés : chaque refus relance la secousse.
  final int rejections;

  SignInState copyWith({
    SignInMethod? method,
    SignInTarget? Function()? target,
    DateTime? Function()? codeSentAt,
    bool? busy,
    String? Function()? errorCode,
    int? rejections,
  }) => SignInState(
    method: method ?? this.method,
    target: target != null ? target() : this.target,
    codeSentAt: codeSentAt != null ? codeSentAt() : this.codeSentAt,
    busy: busy ?? this.busy,
    errorCode: errorCode != null ? errorCode() : this.errorCode,
    rejections: rejections ?? this.rejections,
  );
}

/// Parcours de connexion par code (ADR-0005). Aucune règle métier ici :
/// validation dans le domaine, appels dans les cas d'usage.
final class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  void selectMethod(SignInMethod method) =>
      state = state.copyWith(method: method, errorCode: () => null);

  /// Valide [input] puis demande un code ; `true` si le code est parti.
  Future<bool> sendCode(String input) async {
    if (state.busy) return false;
    final parsed = switch (state.method) {
      SignInMethod.phone => PhoneNumber.parse(input).map(PhoneTarget.new),
      SignInMethod.email => EmailAddress.parse(input).map(EmailTarget.new),
    };
    switch (parsed) {
      case Err(:final error):
        state = state.copyWith(errorCode: () => error.code);
        return false;
      case Ok(value: final SignInTarget target):
        return _request(target);
    }
  }

  /// Connexion par Google ; en cas de succès, le routeur quitte la
  /// connexion. Fermer le choix du compte n'est pas une erreur.
  Future<void> signInWithGoogle() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, errorCode: () => null);
    final result = await ref.read(signInWithGoogleProvider)();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const SignInState(),
      Err(error: GoogleSignInCancelled()) => state.copyWith(busy: false),
      Err(:final error) => state.copyWith(
        busy: false,
        errorCode: () => error.code,
      ),
    };
  }

  /// Redemande un code pour la même destination.
  Future<void> resend() async {
    if (state.target case final target?) await _request(target);
  }

  /// Valide [code] ; en cas de succès, la session s'ouvre et le routeur
  /// quitte la connexion.
  Future<void> verify(String code) async {
    final target = state.target;
    if (target == null || state.busy) return;
    state = state.copyWith(busy: true, errorCode: () => null);
    final result = await ref.read(verifyCodeProvider)(target, code);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const SignInState(),
      Err(:final error) => state.copyWith(
        busy: false,
        errorCode: () => error.code,
        rejections: state.rejections + 1,
      ),
    };
  }

  /// Retour à la saisie du numéro ou de l'adresse.
  void editTarget() => state = state.copyWith(
    target: () => null,
    codeSentAt: () => null,
    errorCode: () => null,
  );

  Future<bool> _request(SignInTarget target) async {
    state = state.copyWith(busy: true, errorCode: () => null);
    final result = await ref.read(requestCodeProvider)(target);
    if (!ref.mounted) return false;
    switch (result) {
      case Ok():
        state = state.copyWith(
          busy: false,
          target: () => target,
          codeSentAt: () => ref.read(clockProvider).now(),
        );
        return true;
      case Err(:final error):
        state = state.copyWith(busy: false, errorCode: () => error.code);
        return false;
    }
  }
}

final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
