import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

/// Client de l'API, construit au démarrage à partir de la configuration
/// (`bootstrap`) ; les tests le remplacent par un client sur un faux
/// adaptateur.
final apiClientProvider = Provider<ApiClient>(
  (ref) =>
      throw UnimplementedError('apiClientProvider est fourni au démarrage'),
);
