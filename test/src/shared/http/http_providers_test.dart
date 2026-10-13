import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

void main() {
  test('le client doit être fourni au démarrage', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(apiClientProvider), throwsA(anything));
  });

  test('ApiClient.create construit un client pour une URL', () {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          ApiClient.create(baseUrl: Uri.parse('https://api.test')),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(apiClientProvider), isA<ApiClient>());
  });
}
