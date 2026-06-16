import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/feature/setting/service/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/view_model/my_info_view_model.dart';
import 'package:iamhere/infrastructure/network/instance/token_refresher.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'my_info_view_model_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserMeServiceInterface>(),
  MockSpec<TokenRefresher>(),
])
void main() {
  late MockUserMeServiceInterface mockUserMeService;
  late MockTokenRefresher mockTokenRefresher;
  late ProviderContainer container;

  final initial = UserMeResponseDto(
    id: 'user-id',
    email: 'user@example.com',
    nickname: '기존닉네임',
    oAuth2Provider: 'KAKAO',
  );

  final updated = UserMeResponseDto(
    id: 'user-id',
    email: 'user@example.com',
    nickname: '새닉네임',
    oAuth2Provider: 'KAKAO',
  );

  setUp(() async {
    mockUserMeService = MockUserMeServiceInterface();
    mockTokenRefresher = MockTokenRefresher();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<UserMeServiceInterface>(
      mockUserMeService,
    );
    GetIt.instance.registerSingleton<TokenRefresher>(mockTokenRefresher);

    when(mockUserMeService.fetchMyInfo()).thenAnswer((_) async => initial);
    when(mockTokenRefresher.refresh()).thenAnswer(
      (_) async => ApiResponse.success(data: 'new-access-token'),
    );

    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await GetIt.instance.reset();
  });

  test('닉네임 변경 성공 시 토큰 refresh 를 호출해야 함', () async {
    when(mockUserMeService.changeNickname('새닉네임')).thenAnswer(
      (_) async => updated,
    );

    await container.read(myInfoViewModelProvider.future);

    final result = await container
        .read(myInfoViewModelProvider.notifier)
        .changeNickname('새닉네임');

    expect(result, isTrue);
    verify(mockUserMeService.changeNickname('새닉네임')).called(1);
    verify(mockTokenRefresher.refresh()).called(1);

    final state = container.read(myInfoViewModelProvider).value;
    expect(state?.nickname, '새닉네임');
  });

  test('토큰 refresh 실패 시 닉네임 변경을 실패로 처리해야 함', () async {
    when(mockUserMeService.changeNickname('새닉네임')).thenAnswer(
      (_) async => updated,
    );
    when(mockTokenRefresher.refresh()).thenAnswer(
      (_) async => ApiResponse.fail(
        imhereErrorCode: 'FAIL',
        errorMessage: 'refresh failed',
      ),
    );

    await container.read(myInfoViewModelProvider.future);

    final result = await container
        .read(myInfoViewModelProvider.notifier)
        .changeNickname('새닉네임');

    expect(result, isFalse);
    verify(mockTokenRefresher.refresh()).called(1);
  });
}
