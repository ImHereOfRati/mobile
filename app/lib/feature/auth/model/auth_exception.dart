sealed class AuthException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AuthException(this.message, {this.stackTrace});

  @override
  String toString() => message;
}

class InvalidTokenException extends AuthException {
  InvalidTokenException({StackTrace? stackTrace})
      : super('Invalid or empty idToken', stackTrace: stackTrace);
}

class InvalidNonceException extends AuthException {
  InvalidNonceException({StackTrace? stackTrace})
      : super('Invalid or empty nonce', stackTrace: stackTrace);
}

class TokenParseException extends AuthException {
  TokenParseException({StackTrace? stackTrace})
      : super('Failed to parse tokens from server response', stackTrace: stackTrace);
}

class TokenStorageException extends AuthException {
  TokenStorageException(String cause, {StackTrace? stackTrace})
      : super('Failed to store tokens: $cause', stackTrace: stackTrace);
}

class ServerAuthException extends AuthException {
  final String responseCode;

  ServerAuthException(this.responseCode, String message, {StackTrace? stackTrace})
      : super('Server auth error ($responseCode): $message', stackTrace: stackTrace);
}

class NetworkException extends AuthException {
  NetworkException(String cause, {StackTrace? stackTrace})
      : super('Network error during authentication: $cause', stackTrace: stackTrace);
}

class InvalidResponseException extends AuthException {
  InvalidResponseException(String cause, {StackTrace? stackTrace})
      : super('Invalid server response: $cause', stackTrace: stackTrace);
}
