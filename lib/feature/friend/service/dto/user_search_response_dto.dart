import 'package:json_annotation/json_annotation.dart';

part 'user_search_response_dto.g.dart';

@JsonSerializable()
class UserSearchResponseDto {
  final String userId;
  final String userEmail;
  final String userNickname;

  UserSearchResponseDto({
    required this.userId,
    required this.userEmail,
    required this.userNickname,
  });

  factory UserSearchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSearchResponseDtoToJson(this);
}
