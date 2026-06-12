import 'package:json_annotation/json_annotation.dart';

part 'change_nickname_request_dto.g.dart';

@JsonSerializable()
class ChangeNicknameRequestDto {
  final String nickname;

  ChangeNicknameRequestDto({required this.nickname});

  Map<String, dynamic> toJson() => _$ChangeNicknameRequestDtoToJson(this);
}
