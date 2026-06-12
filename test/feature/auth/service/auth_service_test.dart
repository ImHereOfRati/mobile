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

  group('AuthService.sendIdTokenToServer - Input Validation', () {
    test('empty idToken 을 거부한다', () async {
      final dio = _FakeDio({});
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(''),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid'),
        )),
      );
    });

    test('whitespace-only idToken 을 거부한다', () async {
      final dio = _FakeDio({});
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer('   '),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService.sendIdTokenToServer - Response Validation', () {
    test('missing accessToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'refreshToken': 'refresh-token',
              // accessToken 누락
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });

    test('missing refreshToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': 'access-token',
              // refreshToken 누락
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });

    test('empty accessToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': '',
              'refreshToken': 'refresh-token',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });

    test('null data 를 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': null,
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });

    test('invalid HTTP status code 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 400,
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

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });

    test('서버 에러 (AUTH-300 아님) 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth/login': Response(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SERVER_ERROR',
            'message': 'Internal error',
            'data': null,
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService.sendIdTokenToServer - Happy Path', () {
    test('PENDING 상태 사용자는 PENDING으로 처리한다', () async {
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
              'status': 'PENDING',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      final result = await authService.sendIdTokenToServer(idToken);

      expect(result, MemberState.pending);
      expect(
        dio.requestedPaths,
        ['/api/auth/login', '/api/auth/registration'],
      );
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
    });

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
