import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';

abstract class UserMeServiceInterface {
  Future<UserMeResponseDto?> fetchMyInfo();
}
