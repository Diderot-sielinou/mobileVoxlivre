import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_user.freezed.dart';

/// Le compte connecté (`GET /v1/me`). `email` est `null` pour un compte créé
/// par téléphone, `phoneNumber` pour un compte créé par e-mail.
@freezed
abstract class CurrentUser with _$CurrentUser {
  const factory CurrentUser({
    required String id,
    String? email,
    String? phoneNumber,
    String? name,
  }) = _CurrentUser;
}
