import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/router.dart';
import 'package:voxlivre/src/features/auth/presentation/auth_routes.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_routes.dart';

void main() {
  const welcome = OnboardingRoutes.welcome;
  const signIn = AuthRoutes.signIn;
  const library = AppRoutes.library;

  String? at(
    String location, {
    required bool signedIn,
    bool onboarded = true,
  }) => guard(signedIn: signedIn, onboarded: onboarded, location: location);

  test('premier lancement sans session : l’onboarding, d’où qu’on vienne', () {
    expect(at(library, signedIn: false, onboarded: false), welcome);
    expect(at(signIn, signedIn: false, onboarded: false), welcome);
    expect(at(welcome, signedIn: false, onboarded: false), isNull);
  });

  test('sans session : seule la connexion est ouverte', () {
    expect(at(library, signedIn: false), signIn);
    expect(at(welcome, signedIn: false), signIn);
    expect(at(signIn, signedIn: false), isNull);
    expect(at(AuthRoutes.code, signedIn: false), isNull);
  });

  test('avec session : connexion et onboarding mènent à la Bibliothèque', () {
    expect(at(signIn, signedIn: true), library);
    expect(at(welcome, signedIn: true, onboarded: false), library);
    expect(at(AppRoutes.profile, signedIn: true, onboarded: false), isNull);
  });
}
