import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iamhere/common/util/app_logger.dart';

/// 런타임 환경 변수 접근 지점.
///
/// 값은 [fileName] 에셋에서 읽으며, dotenv 상태는 아이솔레이트별로 분리되어 있다.
/// 따라서 메인 아이솔레이트뿐 아니라 백그라운드 아이솔레이트도 각자
/// [ensureLoaded] 를 호출해야 한다.
class AppEnv {
  AppEnv._();

  /// pubspec.yaml `flutter/assets` 에 등록되어 있어야 한다.
  static const String fileName = 'iam_here_flutter_secret.env';

  /// 환경 파일을 한 번만 로드한다. 실패해도 예외를 던지지 않으며,
  /// 이 경우 [maybe] 는 null, [require] 는 [StateError] 를 반환/발생시킨다.
  static Future<void> ensureLoaded() async {
    if (dotenv.isInitialized) return;
    try {
      await dotenv.load(fileName: fileName);
    } catch (error) {
      AppLogger.warning('환경 파일($fileName)을 불러오지 못했습니다: $error');
    }
  }

  /// 값이 없거나 비어 있으면 null.
  static String? maybe(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// 값이 없으면 [StateError]. 앱 구동에 필수인 값에만 사용한다.
  static String require(String key) {
    final value = maybe(key);
    if (value == null) {
      throw StateError('환경 변수 $key 가 $fileName 에 정의되어 있지 않습니다.');
    }
    return value;
  }
}
