import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// Ce que la conversion demande au backend ; tout exige le réseau.
abstract interface class ConversionGateway {
  Future<Result<List<Voice>, Failure>> voices();

  /// Solde par source et poids des gammes.
  Future<Result<UnitsAccount, Failure>> account();

  /// Lance (ou retrouve, sans nouveau débit) la conversion de
  /// [documentId] avec [voiceId]. Refus : `QUOTA_EXCEEDED` (402),
  /// `DOCUMENT_REVIEW_REQUIRED`, `QUOTA_CONVERSION_LIMIT_EXCEEDED`…
  Future<Result<Conversion, Failure>> start(String documentId, String voiceId);

  Future<Result<Conversion, Failure>> fetch(String conversionId);
}
