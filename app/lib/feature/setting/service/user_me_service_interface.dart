import 'package:iamhere/feature/setting/model/user_me_response_dto.dart';

abstract class UserMeServiceInterface {
  Future<UserMeResponseDto?> fetchMyInfo();
}
