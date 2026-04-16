import 'package:iamhere/feature/auth/model/login_result.dart';

abstract class AuthServiceInterface {
  Future<MemberState> sendIdTokenToServer(String idToken);
}
