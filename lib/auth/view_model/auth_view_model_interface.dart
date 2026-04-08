import 'package:iamhere/auth/model/login_result.dart';
import 'package:iamhere/common/result/result_message.dart';
import 'package:iamhere/common/result/result.dart';

abstract class AuthViewModelInterface {
  /// 카카오 로그인 처리
  /// Returns: LoginResult.newUser(신규) 또는 LoginResult.existingUser(기존)
  Future<Result<LoginResult>> handleKakaoLogin();
  Future<Result<ResultMessage>> requestFCMTokenAndSendToServer();
}
