import 'package:iamhere/auth/model/login_result.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:iamhere/shared/base/result/result_message.dart';

abstract class AuthViewModelInterface {
  /// 카카오 로그인 처리
  /// Returns: LoginResult.newUser(신규) 또는 LoginResult.existingUser(기존)
  Future<Result<LoginResult>> handleKakaoLogin();
  Future<Result<ResultMessage>> requestFCMTokenAndSendToServer();
}
