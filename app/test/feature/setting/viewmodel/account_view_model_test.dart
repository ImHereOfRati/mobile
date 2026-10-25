import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/viewmodel/auth_invalidation_notifier.dart';
import 'package:iamhere/feature/setting/model/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/viewmodel/account_view_model.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';

UserMeResponseDto _user(String nickname) => UserMeResponseDto(
  id: 'user-1',
  email: 'test@example.com',
  nickname: nickname,
  oAuth2Provider: 'KAKAO',
);

class _FakeUserMeService implements UserMeServiceInterface {
  UserMeResponseDto? me = _user('기존');
  Object? changeError;
  Object? withdrawError;
  final changedNicknames = <String>[];
  var withdrawCalls = 0;

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async => me;

  @override
  Future<UserMeResponseDto> changeNickname(String nickname) async {
    final error = changeError;
    if (error != null) throw error;
    changedNicknames.add(nickname);
    return _user(nickname);
  }

  @override
  Future<void> withdraw() async {
    withdrawCalls++;
    final error = withdrawError;
    if (error != null) throw error;
  }
}

class _FakeTokenStorage implements TokenStorageService {
  Object? deleteError;
  var deleteCalls = 0;

  @override
  Future<void> deleteAllTokens() async {
    deleteCalls++;
    final error = deleteError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnalytics implements AnalyticsReporter {
  final consents = <bool>[];

  @override
  Future<void> setConsent(bool granted) async => consents.add(granted);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}
}

void main() {
  late _FakeUserMeService service;
  late _FakeTokenStorage tokenStorage;
  late _FakeAnalytics analytics;
  late ProviderContainer container;

  AccountViewModelProvider provider() =>
      accountViewModelProvider(service, tokenStorage);

  setUp(() {
    service = _FakeUserMeService();
    tokenStorage = _FakeTokenStorage();
    analytics = _FakeAnalytics();
    container = ProviderContainer(
      overrides: [authAnalyticsReporterProvider.overrideWithValue(analytics)],
    );
    addTearDown(container.dispose);
  });

  test('loads the current user', () async {
    final me = await container.read(provider().future);

    expect(me.nickname, '기존');
  });

  test('fails to load when the user cannot be fetched', () async {
    service.me = null;

    await expectLater(container.read(provider().future), throwsStateError);
  });

  group('changeNickname', () {
    test('trims, saves and publishes the updated user', () async {
      await container.read(provider().future);

      final message = await container
          .read(provider().notifier)
          .changeNickname('  새 닉네임  ');

      expect(message, isNull);
      expect(service.changedNicknames, ['새 닉네임']);
      expect(container.read(provider()).value?.nickname, '새 닉네임');
    });

    test('rejects an empty or too long nickname without a request', () async {
      await container.read(provider().future);
      final notifier = container.read(provider().notifier);

      expect(await notifier.changeNickname('   '), isNotNull);
      expect(
        await notifier.changeNickname('가' * (nicknameMaxLength + 1)),
        isNotNull,
      );
      expect(service.changedNicknames, isEmpty);
    });

    test('keeps the current user when the request fails', () async {
      await container.read(provider().future);
      service.changeError = Exception('boom');

      final message = await container
          .read(provider().notifier)
          .changeNickname('새 닉네임');

      expect(message, '닉네임을 변경하지 못했어요.');
      expect(container.read(provider()).value?.nickname, '기존');
    });
  });

  group('signOut', () {
    test(
      'clears tokens, revokes analytics and requests invalidation',
      () async {
        await container.read(provider().future);

        await container.read(provider().notifier).signOut();

        expect(tokenStorage.deleteCalls, 1);
        expect(analytics.consents, [false]);
        expect(container.read(authInvalidationProvider), 1);
      },
    );
  });

  group('withdraw', () {
    test('clears the session after the account is deleted', () async {
      await container.read(provider().future);

      final message = await container.read(provider().notifier).withdraw();

      expect(message, isNull);
      expect(service.withdrawCalls, 1);
      expect(tokenStorage.deleteCalls, 1);
      expect(analytics.consents, [false]);
      expect(container.read(authInvalidationProvider), 1);
    });

    test('keeps the session when the server refuses', () async {
      await container.read(provider().future);
      service.withdrawError = Exception('boom');

      final message = await container.read(provider().notifier).withdraw();

      expect(message, '회원 탈퇴에 실패했어요.');
      expect(tokenStorage.deleteCalls, 0);
      expect(container.read(authInvalidationProvider), 0);
    });

    test('still invalidates when local cleanup fails after deletion', () async {
      await container.read(provider().future);
      tokenStorage.deleteError = Exception('storage');

      final message = await container.read(provider().notifier).withdraw();

      expect(message, isNull);
      expect(container.read(authInvalidationProvider), 1);
    });
  });
}
