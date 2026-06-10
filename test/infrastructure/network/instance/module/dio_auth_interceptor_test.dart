import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart';
import 'package:iamhere/infrastructure/network/instance/module/dio_auth_interceptor.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dio_auth_interceptor_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TokenStorageService>(),
  MockSpec<AuthTokenRefreshCoordinator>(),
  MockSpec<RequestInterceptorHandler>(),
])
void main() {
  late MockTokenStorageService tokenStorage;
  late MockAuthTokenRefreshCoordinator coordinator;
  late MockRequestInterceptorHandler handler;
  late DioAuthInterceptor interceptor;

  setUp(() {
    tokenStorage = MockTokenStorageService();
    coordinator = MockAuthTokenRefreshCoordinator();
    handler = MockRequestInterceptorHandler();
    interceptor = DioAuthInterceptor(tokenStorage, coordinator);
  });

  test('인증이 필요 없는 요청에는 Authorization 헤더를 추가하지 않는다', () async {
    final options = RequestOptions(path: '/public');

    interceptor.onRequest(options, handler);
    await Future<void>.delayed(Duration.zero);

    expect(options.headers.containsKey('Authorization'), isFalse);
    verifyNever(tokenStorage.getAccessToken());
    verify(handler.next(options)).called(1);
  });

  test('인증이 필요한 요청이고 토큰이 있으면 Authorization 헤더를 추가한다', () async {
    final options = RequestOptions(
      path: '/private',
      extra: {DioAuthInterceptor.authRequirementKey: true},
    );
    when(tokenStorage.getAccessToken()).thenAnswer((_) async => 'token-123');

    interceptor.onRequest(options, handler);
    await Future<void>.delayed(Duration.zero);

    expect(options.headers['Authorization'], 'Bearer token-123');
    verify(tokenStorage.getAccessToken()).called(1);
    verify(handler.next(options)).called(1);
  });
}
