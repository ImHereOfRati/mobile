import 'package:google_sign_in/google_sign_in.dart';
import 'package:iamhere/common/config/app_env.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GoogleAuthService {
  static const _serverClientIdKey = 'GOOGLE_SERVER_CLIENT_ID';

  Future<Result<String?>> login({required String nonce}) async {
    try {
      final serverClientId = AppEnv.maybe(_serverClientIdKey);
      if (serverClientId == null) {
        AppLogger.error(
          'Google sign-in configuration is missing: $_serverClientIdKey',
        );
        return Failure(ResultMessage.googleAuthFailNotGoodResult.toString());
      }

      final googleSignIn = GoogleSignIn.instance;
      AppLogger.debug(
        'Google sign-in SDK initialization started '
        '(serverClientIdConfigured=true, nonceConfigured=${nonce.trim().isNotEmpty})',
      );
      await googleSignIn.initialize(
        serverClientId: serverClientId,
        nonce: nonce,
      );

      AppLogger.debug('Google sign-in authentication started');
      final account = await googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        AppLogger.error('Google sign-in completed without an ID token');
        return Failure(ResultMessage.googleAuthFailNotGoodResult.toString());
      }

      AppLogger.debug('Google sign-in ID token received');
      return Success(idToken);
    } catch (error, stack) {
      AppLogger.error(
        'Google sign-in failed: ${error.runtimeType}: $error',
        error,
        stack,
      );
      return Failure(ResultMessage.googleAuthFail.toString());
    }
  }
}
