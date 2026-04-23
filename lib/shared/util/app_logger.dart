import 'package:flutter/foundation.dart';

/// 앱 전역에서 사용할 로거 유틸리티.
/// 디버그 모드에서만 로그를 출력하고, 릴리즈 빌드에서는 제거되도록 한다.
class AppLogger {
  AppLogger._();

  /// 일반 정보 로그
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// 에러 로그
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// 경고 로그
  static void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }
}
