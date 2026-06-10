import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart';
import 'package:iamhere/infrastructure/network/instance/module/pending_request.dart';
import 'package:iamhere/infrastructure/network/instance/token_refresher.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_token_refresh_coordinator_test.mocks.dart';

@GenerateMocks([
  TokenStorageService,
  TokenRefresher,
  RequestRetrier,
  ErrorInterceptorHandler,
])
void main() {
  late MockTokenStorageService mockStorage;
  late MockTokenRefresher mockRefresher;
  late MockRequestRetrier mockRetrier;
  late AuthTokenRefreshCoordinator coordinator;

  setUp(() {
    mockStorage = MockTokenStorageService();
    mockRefresher = MockTokenRefresher();
    mockRetrier = MockRequestRetrier();
    coordinator = AuthTokenRefreshCoordinator(
      mockStorage,
      mockRefresher,
      mockRetrier,
    );
  });

  test('handleUnauthorized_토큰_갱신에_성공하면_대기중인_요청을_재시도한다', () async {
    final requestOptions = RequestOptions(path: '/api/friends');
    final handler = MockErrorInterceptorHandler();
    when(
      mockRefresher.refresh(),
    ).thenAnswer((_) async => ApiResponse.success(data: 'new-token'));
    when(mockRetrier.retryAll(any)).thenAnswer((_) async {});

    await coordinator.handleUnauthorized(
      DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      ),
      handler,
    );

    verify(mockRetrier.addToQueue(requestOptions, handler)).called(1);
    verify(mockRetrier.retryAll('new-token')).called(1);
    verifyNever(mockStorage.deleteAllTokens());
  });

  test('handleUnauthorized_토큰_갱신에_실패하면_모든_토큰을_삭제하고_로그아웃한다', () async {
    final requestOptions = RequestOptions(path: '/api/friends');
    final handler = MockErrorInterceptorHandler();
    when(mockRefresher.refresh()).thenAnswer(
      (_) async => ApiResponse.fail(
        imhereErrorCode: 'AUTH-104',
        errorMessage: 'expired',
      ),
    );
    when(mockStorage.deleteAllTokens()).thenAnswer((_) async {});

    await coordinator.handleUnauthorized(
      DioException(
        requestOptions: requestOptions,
        response: Response(requestOptions: requestOptions, statusCode: 401),
      ),
      handler,
    );

    verify(mockStorage.deleteAllTokens()).called(1);
    verify(mockRetrier.failAll(any)).called(1);
    verify(handler.reject(any)).called(1);
  });

  test('handleUnauthorized_토큰_갱신중일때_새로운_요청이오면_갱신하지않고_대기열에_추가한다', () async {
    final requestOptions1 = RequestOptions(path: '/api/first');
    final requestOptions2 = RequestOptions(path: '/api/second');
    final handler1 = MockErrorInterceptorHandler();
    final handler2 = MockErrorInterceptorHandler();

    when(mockRefresher.refresh()).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 50),
        () => ApiResponse.success(data: 'new-token'),
      ),
    );
    when(mockRetrier.retryAll(any)).thenAnswer((_) async {});

    // 첫 번째 권한 없음 요청 발생 (토큰 갱신 시작)
    final firstRequest = coordinator.handleUnauthorized(
      DioException(
        requestOptions: requestOptions1,
        response: Response(requestOptions: requestOptions1, statusCode: 401),
      ),
      handler1,
    );

    // 두 번째 권한 없음 요청 발생 (갱신 중인 상태)
    await coordinator.handleUnauthorized(
      DioException(
        requestOptions: requestOptions2,
        response: Response(requestOptions: requestOptions2, statusCode: 401),
      ),
      handler2,
    );

    // 첫 번째 요청 완료 대기
    await firstRequest;

    // refresh는 단 1번만 호출되어야 함
    verify(mockRefresher.refresh()).called(1);

    // 두 요청 모두 큐에 추가되었어야 함
    verify(mockRetrier.addToQueue(requestOptions1, handler1)).called(1);
    verify(mockRetrier.addToQueue(requestOptions2, handler2)).called(1);
  });

  test('isRefreshRequest_리프레시_엔드포인트면_true를_반환한다', () {
    expect(coordinator.isRefreshRequest('/api/auth/refresh'), isTrue);
    expect(coordinator.isRefreshRequest('/api/friends'), isFalse);
  });

  test('forceLogout_토큰을_삭제하고_대기열을_실패처리한다', () async {
    final requestOptions = RequestOptions(path: '/api/friends');
    final handler = MockErrorInterceptorHandler();
    final error = DioException(requestOptions: requestOptions);
    when(mockStorage.deleteAllTokens()).thenAnswer((_) async {});

    await coordinator.forceLogout(error, handler);

    verify(mockStorage.deleteAllTokens()).called(1);
    verify(mockRetrier.failAll(error)).called(1);
    verify(handler.reject(error)).called(1);
  });
}
