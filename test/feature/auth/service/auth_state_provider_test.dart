import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/feature/auth/service/auth_state.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_state_provider_test.mocks.dart';

@GenerateMocks([TokenStorageService])
void main() {
  late MockTokenStorageService mockTokenStorageService;
  late ProviderContainer container;

  setUp(() async {
    mockTokenStorageService = MockTokenStorageService();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<TokenStorageService>(
      mockTokenStorageService,
    );

    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await GetIt.instance.reset();
  });

  group('auth_state_provider_test', () {
    test('AccessToken이 존재하면 authenticated 를 반환한다.', () async {
      //given
      final testAccessToken = 'access_token';

      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => testAccessToken);
      when(
        mockTokenStorageService.getPendingAuth(),
      ).thenAnswer((_) async => false);
      when(
        mockTokenStorageService.getUserStatus(),
      ).thenAnswer((_) async => null);
      when(mockTokenStorageService.getIsActive()).thenAnswer((_) async => true);

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, AuthState.authenticated);
    });

    test('pending 플래그가 있으면 pending 을 반환한다.', () async {
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'access_token');
      when(
        mockTokenStorageService.getPendingAuth(),
      ).thenAnswer((_) async => true);

      final result = await container.read(authStateProvider.future);

      expect(result, AuthState.pending);
    });

    test('isActive 가 false 이면 inactive 를 반환한다.', () async {
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'access_token');
      when(
        mockTokenStorageService.getPendingAuth(),
      ).thenAnswer((_) async => false);
      when(
        mockTokenStorageService.getUserStatus(),
      ).thenAnswer((_) async => 'ACTIVE');
      when(
        mockTokenStorageService.getIsActive(),
      ).thenAnswer((_) async => false);

      final result = await container.read(authStateProvider.future);

      expect(result, AuthState.inactive);
    });

    test('없으면 unauthenticated 를 반환한다', () async {
      //given
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => null);

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, AuthState.unauthenticated);
      verify(mockTokenStorageService.getAccessToken()).called(1);
    });

    test('빈 문자열이어도 unauthenticated 를 반환한다', () async {
      //given
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => '');

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, AuthState.unauthenticated);
      verify(mockTokenStorageService.getAccessToken()).called(1);
    });
  });
}
