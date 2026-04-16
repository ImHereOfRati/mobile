import 'package:json_annotation/json_annotation.dart';

part 'friend_restriction_deleted_response_dto.g.dart';

@JsonSerializable()
class FriendRestrictionDeletedResponseDto {
  final String targetEmail;

  FriendRestrictionDeletedResponseDto({
    required this.targetEmail,
  });

  factory FriendRestrictionDeletedResponseDto.fromJson(
          Map<String, dynamic> json) =>
      _$FriendRestrictionDeletedResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$FriendRestrictionDeletedResponseDtoToJson(this);
}
