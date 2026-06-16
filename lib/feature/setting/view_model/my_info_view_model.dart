import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/infrastructure/network/instance/token_refresher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_info_view_model.g.dart';

@riverpod
class MyInfoViewModel extends _$MyInfoViewModel {
  late final UserMeServiceInterface _service;
  late final TokenRefresher _tokenRefresher;

  @override
  Future<UserMeResponseDto?> build() async {
    _service = getIt<UserMeServiceInterface>();
    _tokenRefresher = getIt<TokenRefresher>();
    return _service.fetchMyInfo();
  }

  /// 닉네임 변경. 성공 시 true 반환 및 상태 갱신.
  Future<bool> changeNickname(String newNickname) async {
    final trimmed = newNickname.trim();
    if (trimmed.isEmpty) return false;

    final updated = await _service.changeNickname(trimmed);
    if (updated == null) return false;

    try {
      final refreshed = await _tokenRefresher.refresh();
      if (refreshed.imhereResponseCode != 'SUCCESS' || refreshed.data == null) {
        return false;
      }
    } catch (e, st) {
      AppLogger.error('닉네임 변경 후 토큰 refresh 실패', e, st);
      return false;
    }

    state = AsyncData(updated);
    return true;
  }
}
