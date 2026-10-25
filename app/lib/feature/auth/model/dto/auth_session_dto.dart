import 'auth_response.dart';

class AuthSessionDto {
  const AuthSessionDto({required this.statusCode, required this.response});

  final int statusCode;
  final AuthResponseDto response;
}
