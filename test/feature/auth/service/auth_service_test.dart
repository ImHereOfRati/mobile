import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';

class _FakeDio extends Fake implements Dio {
  final Map<String, Response<dynamic>> responses;
  final List<String> requestedPaths = [];
  final List<Object?> requestedBodies = [];

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
    requestedBodies.add(data);
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
  bool pendingAuth = false;
  String? userStatus;
  bool? isActive;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> savePendingAuth(bool isPending) async {
    pendingAuth = isPending;
  }

  @override
  Future<void> saveAuthSnapshot({String? userStatus, bool? isActive}) async {
    this.userStatus = userStatus;
    this.isActive = isActive;
    pendingAuth = userStatus == 'PENDING';
  }
}

void main() {
  late _FakeTokenStorageService tokenStorage;

  const idToken = 'id-token';
  const nonce = 'nonce-token';

  setUp(() {
    tokenStorage = _FakeTokenStorageService();
  });

  group('AuthService.sendIdTokenToServer - Input Validation', () {
    test('empty idToken 을 거부한다', () async {
      final dio = _FakeDio({});
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer('', nonce: nonce),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid'),
          ),
        ),
      );
    });

    test('whitespace-only idToken 을 거부한다', () async {
      final dio = _FakeDio({});
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer('   ', nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('empty nonce 를 거부한다', () async {
      final dio = _FakeDio({});
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken, nonce: ''),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService.sendIdTokenToServer - Response Validation', () {
    test('missing accessToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('missing refreshToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('empty accessToken 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {'accessToken': '', 'refreshToken': 'refresh-token'},
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      expect(
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('null data 를 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('invalid HTTP status code 을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });

    test('서버 에러 응답을 거부한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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
        () => authService.sendIdTokenToServer(idToken, nonce: nonce),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AuthService.sendIdTokenToServer - Happy Path', () {
    test('PENDING 상태 사용자는 PENDING으로 처리한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'userStatus': 'PENDING',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      final result = await authService.sendIdTokenToServer(
        idToken,
        nonce: nonce,
      );

      expect(result, MemberState.pending);
      expect(dio.requestedPaths, ['/api/auth']);
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
      expect(tokenStorage.pendingAuth, isTrue);
    });

    test('ACTIVE 상태 사용자는 기존 사용자로 처리한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
          statusCode: 200,
          data: {
            'imhereResponseCode': 'SUCCESS',
            'message': 'OK',
            'data': {
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
              'userStatus': 'ACTIVE',
            },
          },
        ),
      });
      final authService = AuthService(dio, tokenStorage);

      final result = await authService.sendIdTokenToServer(
        idToken,
        nonce: nonce,
      );

      expect(result, MemberState.existingUser);
      expect(dio.requestedPaths, ['/api/auth']);
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
      expect(tokenStorage.pendingAuth, isFalse);
    });

    test('기존 사용자는 login 응답만으로 처리한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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

      final result = await authService.sendIdTokenToServer(
        idToken,
        nonce: nonce,
      );

      expect(result, MemberState.existingUser);
      expect(dio.requestedPaths, ['/api/auth']);
      expect(tokenStorage.accessToken, 'access-token');
      expect(tokenStorage.refreshToken, 'refresh-token');
      expect(tokenStorage.pendingAuth, isFalse);
    });

    test('Google provider 는 요청 body provider 를 GOOGLE 로 전송한다', () async {
      final dio = _FakeDio({
        '/api/auth': Response(
          requestOptions: RequestOptions(path: '/api/auth'),
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

      final result = await authService.sendIdTokenToServer(
        idToken,
        nonce: nonce,
        provider: OauthProvider.google,
      );

      expect(result, MemberState.existingUser);
      expect(dio.requestedBodies.first, {
        'provider': 'GOOGLE',
        'idToken': idToken,
        'nonce': nonce,
      });
    });
  });

  test('약관 동의 후 토큰을 갱신하고 ACTIVE 스냅샷을 저장한다', () async {
    final dio = _FakeDio({
      '/api/agreements': Response<void>(
        requestOptions: RequestOptions(path: '/api/agreements'),
        statusCode: 204,
      ),
      '/api/auth/refresh': Response(
        requestOptions: RequestOptions(path: '/api/auth/refresh'),
        statusCode: 200,
        data: {
          'imhereResponseCode': 'SUCCESS',
          'message': 'OK',
          'data': {
            'accessToken': 'active-access',
            'refreshToken': 'active-refresh',
            'userStatus': 'ACTIVE',
            'isActive': true,
          },
        },
      ),
    });
    final authService = AuthService(dio, tokenStorage);
    tokenStorage.refreshToken = 'pending-refresh';

    await authService.activateWithTerms([
      {'id': 1, 'agreed': true},
      {'id': 2, 'agreed': false},
    ]);

    expect(dio.requestedPaths, ['/api/agreements', '/api/auth/refresh']);
    expect(dio.requestedBodies.first, {
      'consents': [
        {'id': 1, 'agreed': true},
        {'id': 2, 'agreed': false},
      ],
    });
    expect(dio.requestedBodies.last, {'refreshToken': 'pending-refresh'});
    expect(tokenStorage.accessToken, 'active-access');
    expect(tokenStorage.refreshToken, 'active-refresh');
    expect(tokenStorage.userStatus, 'ACTIVE');
    expect(tokenStorage.isActive, isTrue);
  });
}
