import 'auth_response.dart';

class AuthApiResponseDto {
  const AuthApiResponseDto({required this.statusCode, required this.data});

  final int statusCode;
  final AuthResponseDto data;
}
