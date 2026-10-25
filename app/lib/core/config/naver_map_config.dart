import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/core/config/app_env.dart';
import 'package:iamhere/core/util/app_logger.dart';

/// 네이버 지도 SDK 초기화. 지도 위젯을 그리기 전에 한 번 끝나 있어야 한다.
///
/// 지도 타일에는 공개 클라이언트 ID만 쓴다. 장소 검색과 지오코딩의 시크릿 키는
/// 앱에 두지 않고 서버 프록시가 갖는다.
abstract final class NaverMapConfig {
  static bool _available = false;

  /// 지도를 그릴 수 있는지. 클라이언트 ID가 없거나 초기화가 실패하면 false.
  static bool get isAvailable => _available;

  static Future<void> initialize() async {
    final clientId = AppEnv.maybe('NAVER_MAP_CLIENT_ID');
    if (clientId == null) {
      AppLogger.warning('NAVER_MAP_CLIENT_ID가 없어 지도를 쓸 수 없습니다.');
      return;
    }
    try {
      await FlutterNaverMap().init(
        clientId: clientId,
        onAuthFailed: (error) =>
            AppLogger.error('Naver map auth failed: $error'),
      );
      _available = true;
    } catch (error, stack) {
      AppLogger.error('Naver map initialization failed', error, stack);
    }
  }

  /// 테스트에서 지도 사용 가능 여부를 바꾼다.
  static void debugSetAvailable(bool value) => _available = value;
}
