import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/conversion/application/fetch_conversion.dart';
import 'package:voxlivre/src/features/conversion/application/load_conversion_options.dart';
import 'package:voxlivre/src/features/conversion/application/start_conversion.dart';
import 'package:voxlivre/src/features/conversion/conversion_providers.dart';
import 'package:voxlivre/src/features/conversion/infrastructure/api_conversion_gateway.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

import '../../../helpers/fake_http.dart';

void main() {
  test('la composition relie l’API et les cas d’usage', () {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          FakeHttp((_) => reply(200)).client(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(conversionGatewayProvider),
      isA<ApiConversionGateway>(),
    );
    expect(
      container.read(loadConversionOptionsProvider),
      isA<LoadConversionOptions>(),
    );
    expect(container.read(startConversionProvider), isA<StartConversion>());
    expect(container.read(fetchConversionProvider), isA<FetchConversion>());
  });
}
