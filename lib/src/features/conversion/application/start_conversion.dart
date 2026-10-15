import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_gateway.dart';

/// Lance la conversion d'un document avec une voix ; relancer la même
/// conversion ne débite pas deux fois (backend).
final class StartConversion {
  const StartConversion(this._gateway);

  final ConversionGateway _gateway;

  Future<Result<Conversion, Failure>> call(String documentId, String voiceId) =>
      _gateway.start(documentId, voiceId);
}
