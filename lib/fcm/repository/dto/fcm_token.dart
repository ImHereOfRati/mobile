import 'dart:io' show Platform;

import 'package:json_annotation/json_annotation.dart';

part 'fcm_token.g.dart';

/// FCM 토큰 등록 요청 모델
@JsonSerializable()
class FcmToken {
  @JsonKey(name: 'fcmToken')
  final String fcmToken;

  @JsonKey(name: 'deviceType')
  final String deviceType;

  FcmToken({required this.fcmToken, required this.deviceType});

  /// 현재 플랫폼을 자동 감지하여 FcmToken을 생성
  factory FcmToken.fromCurrentPlatform({required String fcmToken}) {
    final deviceType = Platform.isIOS ? 'IOS' : 'AOS';
    return FcmToken(fcmToken: fcmToken, deviceType: deviceType);
  }

  Map<String, dynamic> toJson() => _$FcmTokenToJson(this);
}
