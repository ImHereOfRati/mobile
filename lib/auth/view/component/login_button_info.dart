import 'package:flutter/material.dart';

@immutable
class LoginButtonInfo {
  final Color backgroundColor;
  final String description;
  final String assetAddress;
  final bool border;

  const LoginButtonInfo({
    required this.backgroundColor,
    required this.description,
    required this.assetAddress,
    this.border = false,
  });
}

class LoginInfoData {
  static const kakao = LoginButtonInfo(
    backgroundColor: Color(0xFFFEE500),
    description: '카카오 로그인',
    assetAddress: 'assets/images/kakaotalk_ballon.png',
  );
}
