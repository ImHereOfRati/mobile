import 'package:flutter/material.dart';
import 'package:iamhere/core/router/app_routes.dart';

/// 카카오 로그인 후 사용자 상태를 나타내는 enum
enum LoginResult {
  /// HTTP 201 - 신규 사용자 (약관 동의 필요)
  newUser,

  /// HTTP 200 - 기존 사용자 (직접 메인 화면으로)
  existingUser;

  /// 로그인 결과에 따라 적절한 화면으로 이동합니다.
  /// newUser → 약관 동의, existingUser → 메인(지오펜스)
  void navigate(BuildContext context) {
    final routes = <LoginResult, void Function(BuildContext)>{
      LoginResult.newUser: AppRoutes.goToTermsConsent,
      LoginResult.existingUser: AppRoutes.goToGeofence,
    };
    routes[this]?.call(context);
  }
}
