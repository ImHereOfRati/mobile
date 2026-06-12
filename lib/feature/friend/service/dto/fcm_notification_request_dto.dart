import 'package:json_annotation/json_annotation.dart';

part 'fcm_notification_request_dto.g.dart';

@JsonSerializable()
class FcmNotificationRequestDto {
  final String notificationMethod;
  @JsonKey(name: 'targetId')
  final String targetId;
  final String type;
  final Map<String, dynamic> extraData;

  FcmNotificationRequestDto({
    required this.notificationMethod,
    required this.targetId,
    required this.type,
    this.extraData = const {},
  });

  factory FcmNotificationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$FcmNotificationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FcmNotificationRequestDtoToJson(this);
}
