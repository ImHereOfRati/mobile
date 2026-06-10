import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

class _FakeDio extends Fake implements Dio {
  final Map<String, Response<dynamic>> responses;
  final List<String> requestedPaths = [];

  _FakeDio(this.responses);

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    requestedPaths.add(path);
    final response = responses[path];
    if (response == null) {
      throw StateError('No fake response configured for $path');
    }
    return response as Response<T>;
  }
}

class _FakeTokenStorageService extends Fake implements TokenStorageService {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }
}

void main() {
  late _FakeTokenStorageService tokenStorage;

  const idToken = 'id-token';

  setUp(() {
    tokenStorage = _FakeTokenStorageService();
  });

  group('AuthService.sendIdTokenToServer', () {
    test('AUTH-300 이면 registration 으로 폴백해 신규 사용자로 처리한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 404,
          data: {
            'imhereResponseCode': 'AUTH-300',
            'message': '사용자 정보를 찾을 수 없습니다.',
            'data': <String, dynamic>{},
          },
        ),
        '/api/auth/registration': Response(
          requestOptions: RequestOptions(path: '/api/auth/registration'),
          statusCode: 201,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      final result = await authService.sendIdTokenToServer(idToken);

      expect(result, MemberState.newUser);
      expect(
        dio.requestedPaths,
        ['/api/auth/login', '/api/auth/registration'],
      );
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
    });

    test('기존 사용자는 login 응답만으로 처리한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      final result = await authService.sendIdTokenToServer(idToken);

      expect(result, MemberState.existingUser);
      expect(dio.requestedPaths, ['/api/auth/login']);
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
    });
  });
}
