import 'package:iamhere/feature/setting/model/dto/user_me_response_dto.dart';

abstract class UserMeServiceInterface {
  Future<UserMeResponseDto?> fetchMyInfo();

  /// 실패하면 예외를 던진다. 인증이 끊긴 경우는 [InvalidAuthStateException].
  Future<UserMeResponseDto> changeNickname(String nickname);

  /// 서버 계정을 삭제한다. 기기에 남은 토큰 정리는 호출자 몫이다.
  Future<void> withdraw();
}
