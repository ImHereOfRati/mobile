import 'package:json_annotation/json_annotation.dart';

part 'change_nickname_request_dto.g.dart';

@JsonSerializable()
class ChangeNicknameRequestDto {
  final String newNickname;

  ChangeNicknameRequestDto({required this.newNickname});

  Map<String, dynamic> toJson() => _$ChangeNicknameRequestDtoToJson(this);
}
