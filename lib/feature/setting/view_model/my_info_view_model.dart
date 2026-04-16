import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_info_view_model.g.dart';

@riverpod
class MyInfoViewModel extends _$MyInfoViewModel {
  @override
  Future<UserMeResponseDto?> build() async {
    final service = getIt<UserMeServiceInterface>();
    return service.fetchMyInfo();
  }
}
