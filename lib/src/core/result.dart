import 'package:meta/meta.dart';

/// Succès typé ou échec typé, sans exception (calque du `Result` du backend).
///
/// Les cas d'usage renvoient leurs échecs métier dans le type de retour :
/// aucune exception métier ne traverse `domain/` ni `application/`. La
/// classe est scellée : un `switch` sur un `Result` doit traiter `Ok` et `Err`,
/// le compilateur le vérifie.
@immutable
sealed class Result<T, E> {
  const Result();

  /// Succès portant [value].
  const factory Result.ok(T value) = Ok<T, E>;

  /// Échec portant [error].
  const factory Result.err(E error) = Err<T, E>;

  /// `true` pour un succès.
  bool get isOk => this is Ok<T, E>;

  /// `true` pour un échec.
  bool get isErr => this is Err<T, E>;

  /// Transforme la valeur d'un succès ; un échec est rendu tel quel.
  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
    Ok(:final value) => Result.ok(transform(value)),
    Err(:final error) => Result.err(error),
  };

  /// Transforme l'erreur d'un échec ; un succès est rendu tel quel.
  Result<T, F> mapErr<F>(F Function(E error) transform) => switch (this) {
    Ok(:final value) => Result.ok(value),
    Err(:final error) => Result.err(transform(error)),
  };

  /// Enchaîne une opération qui peut elle-même échouer.
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) next) =>
      switch (this) {
        Ok(:final value) => next(value),
        Err(:final error) => Result.err(error),
      };

  /// La valeur d'un succès, ou [fallback] pour un échec.
  T valueOr(T fallback) => switch (this) {
    Ok(:final value) => value,
    Err() => fallback,
  };
}

/// Succès.
@immutable
final class Ok<T, E> extends Result<T, E> {
  /// Succès portant [value].
  const Ok(this.value);

  /// La valeur produite.
  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Échec.
@immutable
final class Err<T, E> extends Result<T, E> {
  /// Échec portant [error].
  const Err(this.error);

  /// L'erreur, en général une `Failure`.
  final E error;

  @override
  bool operator ==(Object other) => other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash(Err, error);

  @override
  String toString() => 'Err($error)';
}
