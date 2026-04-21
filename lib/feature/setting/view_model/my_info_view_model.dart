import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_info_view_model.g.dart';

@riverpod
class MyInfoViewModel extends _$MyInfoViewModel {
  late final UserMeServiceInterface _service;

  @override
  Future<UserMeResponseDto?> build() async {
    _service = getIt<UserMeServiceInterface>();
    return _service.fetchMyInfo();
  }

  /// 닉네임 변경. 성공 시 true 반환 및 상태 갱신.
  Future<bool> changeNickname(String newNickname) async {
    final trimmed = newNickname.trim();
    if (trimmed.isEmpty) return false;

    final updated = await _service.changeNickname(trimmed);
    if (updated == null) return false;

    state = AsyncData(updated);
    return true;
  }
}
