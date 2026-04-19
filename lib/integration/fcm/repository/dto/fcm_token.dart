import 'package:json_annotation/json_annotation.dart';

import 'device_type.dart';

part 'fcm_token.g.dart';

@JsonSerializable()
class FcmToken {
  @JsonKey(name: 'fcmToken')
  final String fcmToken;

  @JsonKey(name: 'deviceType')
  final String deviceType;

  FcmToken({required this.fcmToken, required this.deviceType});

  factory FcmToken.fromCurrentPlatform({required String fcmToken}) {
    return FcmToken(
      fcmToken: fcmToken,
      deviceType: DeviceType.getDeviceType().description,
    );
  }

  Map<String, dynamic> toJson() => _$FcmTokenToJson(this);
}
