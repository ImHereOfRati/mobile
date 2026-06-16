import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GoogleAuthService {
  static const _serverClientIdKey = 'GOOGLE_SERVER_CLIENT_ID';

  Future<Result<String?>> login({required String nonce}) async {
    try {
      final serverClientId = dotenv.env[_serverClientIdKey];
      if (serverClientId == null || serverClientId.isEmpty) {
        return Failure(ResultMessage.googleAuthFailNotGoodResult.toString());
      }

      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: serverClientId,
        nonce: nonce,
      );

      final account = await googleSignIn.authenticate();
      if (account == null) {
        return Failure(ResultMessage.googleLoginCanceled.toString());
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        return Failure(ResultMessage.googleAuthFailNotGoodResult.toString());
      }

      return Success(idToken);
    } catch (_) {
      return Failure(ResultMessage.googleAuthFail.toString());
    }
  }
}
