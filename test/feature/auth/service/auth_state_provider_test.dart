import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
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
    test('AccessToken이 존재하면 true 를 반환한다.', () async {
      //given
      final testAccessToken = 'access_token';

      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => testAccessToken);

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, true);
    });

    test('없으면 false를 반환한다', () async {
      //given
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => null);

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, false);
      verify(mockTokenStorageService.getAccessToken()).called(1);
    });

    test('빈 문자열이어도 false를 반환한다', () async {
      //given
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => '');

      //when
      final result = await container.read(authStateProvider.future);

      //then
      expect(result, false);
      verify(mockTokenStorageService.getAccessToken()).called(1);
    });
  });
}
