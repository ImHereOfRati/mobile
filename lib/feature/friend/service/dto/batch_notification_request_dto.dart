import 'package:json_annotation/json_annotation.dart';

part 'batch_notification_request_dto.g.dart';

@JsonSerializable()
class BatchNotificationRequestDto {
  final String notificationMethod;
  final List<String> targetIds;
  final String type;
  final Map<String, dynamic> extraData;

  BatchNotificationRequestDto({
    required this.notificationMethod,
    required this.targetIds,
    required this.type,
    this.extraData = const {},
  });

  factory BatchNotificationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$BatchNotificationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$BatchNotificationRequestDtoToJson(this);
}
