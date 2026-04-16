import 'package:iamhere/feature/friend/service/dto/user_search_response_dto.dart';

abstract class UserSearchServiceInterface {
  Future<List<UserSearchResponseDto>> searchByNickname(String keyword);
}
