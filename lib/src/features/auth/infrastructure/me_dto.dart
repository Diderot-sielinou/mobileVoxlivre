import 'package:json_annotation/json_annotation.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';

part 'me_dto.g.dart';

/// Réponse de `GET /v1/me` (`MeResponseDto` du backend) ; seuls les champs
/// utiles à l'app sont lus.
@JsonSerializable(createToJson: false)
final class MeDto {
  const MeDto({required this.id, this.email, this.phoneNumber, this.name});

  factory MeDto.fromJson(Map<String, Object?> json) => _$MeDtoFromJson(json);

  final String id;
  final String? email;
  final String? phoneNumber;
  final String? name;

  CurrentUser toDomain() =>
      CurrentUser(id: id, email: email, phoneNumber: phoneNumber, name: name);
}
