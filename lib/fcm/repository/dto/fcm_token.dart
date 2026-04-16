import 'dart:io' show Platform;

import 'package:json_annotation/json_annotation.dart';

part 'fcm_token.g.dart';

@JsonSerializable()
class FcmToken {
  @JsonKey(name: 'fcmToken')
  final String fcmToken;

  @JsonKey(name: 'deviceType')
  final String deviceType;

  FcmToken({required this.fcmToken, required this.deviceType});

  factory FcmToken.fromCurrentPlatform({required String fcmToken}) {
    final deviceType = Platform.isIOS ? 'IOS' : 'AOS';
    return FcmToken(fcmToken: fcmToken, deviceType: deviceType);
  }

  Map<String, dynamic> toJson() => _$FcmTokenToJson(this);
}
