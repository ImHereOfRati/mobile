import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';

abstract class OAuthAuthService {
  OauthProvider get provider;

  Future<Result<String?>> login({required String nonce});
}
