import 'package:json_annotation/json_annotation.dart';

part 'fcm_notification_request_dto.g.dart';

@JsonSerializable()
class FcmNotificationRequestDto {
  final String receiverEmail;
  final String type;
  final String body;

  FcmNotificationRequestDto({
    required this.receiverEmail,
    required this.type,
    required this.body,
  });

  factory FcmNotificationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$FcmNotificationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FcmNotificationRequestDtoToJson(this);
}
