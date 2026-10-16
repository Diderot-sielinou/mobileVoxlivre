import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/signed_download.dart';
import 'package:voxlivre/src/shared/http/signed_upload.dart';

/// Client de l'API, construit au démarrage à partir de la configuration
/// (`bootstrap`) ; les tests le remplacent par un client sur un faux
/// adaptateur.
final apiClientProvider = Provider<ApiClient>(
  (ref) =>
      throw UnimplementedError('apiClientProvider est fourni au démarrage'),
);

/// Envoi direct vers une URL signée du stockage (ADR-0007).
final signedUploadProvider = Provider<SignedUpload>(
  (ref) => SignedUpload.create(),
);

/// Lecture directe d'un fichier signé du stockage (ADR-0010).
final signedDownloadProvider = Provider<SignedDownload>(
  (ref) => SignedDownload.create(),
);
