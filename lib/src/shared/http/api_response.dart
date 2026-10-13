/// Réponse réussie, telle que la voit un décodeur.
final class ApiResponse {
  /// Réponse de corps [json] et d'en-têtes [headers] (noms en minuscules).
  const ApiResponse(this.json, [this.headers = const {}]);

  /// Corps décodé, `null` s'il est vide.
  final Object? json;

  /// En-têtes, noms en minuscules.
  final Map<String, List<String>> headers;

  /// Première valeur de l'en-tête [name] (insensible à la casse), ou `null`.
  String? header(String name) => headers[name.toLowerCase()]?.firstOrNull;
}
