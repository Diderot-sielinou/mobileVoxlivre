import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/conversion/application/fetch_conversion.dart';
import 'package:voxlivre/src/features/conversion/application/load_conversion_options.dart';
import 'package:voxlivre/src/features/conversion/application/start_conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';
import 'package:voxlivre/src/features/conversion/infrastructure/api_conversion_gateway.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

/// Composition de la conversion (ADR-0002, ADR-0008).

final conversionGatewayProvider = Provider<ConversionGateway>(
  (ref) => ApiConversionGateway(ref.watch(apiClientProvider)),
);

final loadConversionOptionsProvider = Provider<LoadConversionOptions>(
  (ref) => LoadConversionOptions(ref.watch(conversionGatewayProvider)),
);

final startConversionProvider = Provider<StartConversion>(
  (ref) => StartConversion(ref.watch(conversionGatewayProvider)),
);

final fetchConversionProvider = Provider<FetchConversion>(
  (ref) => FetchConversion(ref.watch(conversionGatewayProvider)),
);
