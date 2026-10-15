import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';

/// Relit l'état d'une conversion.
final class FetchConversion {
  const FetchConversion(this._gateway);

  final ConversionGateway _gateway;

  Future<Result<Conversion, Failure>> call(String conversionId) =>
      _gateway.fetch(conversionId);
}
