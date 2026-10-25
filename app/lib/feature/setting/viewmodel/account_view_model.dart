import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/viewmodel/auth_invalidation_notifier.dart';
import 'package:iamhere/feature/setting/model/dto/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/model/service/user_me_service_interface.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_view_model.g.dart';

const nicknameMaxLength = 30;

@riverpod
class AccountViewModel extends _$AccountViewModel {
  late UserMeServiceInterface _service;
  late TokenStorageService _tokenStorage;

  @override
  Future<UserMeResponseDto> build(
    UserMeServiceInterface service,
    TokenStorageService tokenStorage,
  ) async {
    _service = service;
    _tokenStorage = tokenStorage;
    final me = await service.fetchMyInfo();
    if (me == null) throw StateError('Failed to load current user.');
    return me;
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> changeNickname(String raw) async {
    final nickname = raw.trim();
    if (nickname.isEmpty || nickname.length > nicknameMaxLength) {
      return '닉네임은 1~$nicknameMaxLength자로 입력해 주세요.';
    }
    try {
      final updated = await _service.changeNickname(nickname);
      if (ref.mounted) state = AsyncData(updated);
      return null;
    } catch (error, stack) {
      AppLogger.error('Nickname change failed', error, stack);
      return '닉네임을 변경하지 못했어요.';
    }
  }

  Future<void> signOut() => _clearSession();

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> withdraw() async {
    try {
      await _service.withdraw();
    } catch (error, stack) {
      AppLogger.error('Withdrawal failed', error, stack);
      return '회원 탈퇴에 실패했어요.';
    }
    // 계정은 이미 지워졌다. 기기 정리가 실패해도 로그인 화면으로 돌려보내는
    // 편이 맞다 — 지워진 계정의 토큰을 들고 앱에 남아 있을 이유가 없다.
    try {
      await _clearSession();
    } catch (error, stack) {
      AppLogger.error('Session cleanup after withdrawal failed', error, stack);
      _requestInvalidation();
    }
    return null;
  }

  Future<void> _clearSession() async {
    await _revokeAnalyticsConsent();
    await _tokenStorage.deleteAllTokens();
    _requestInvalidation();
  }

  // 계정이 바뀌어도 이전 사용자의 분석 동의가 남지 않게 한다. 실패해도
  // 로그아웃은 막지 않는다.
  Future<void> _revokeAnalyticsConsent() async {
    try {
      await ref.read(authAnalyticsReporterProvider).setConsent(false);
    } catch (error, stack) {
      AppLogger.error('Analytics consent reset failed', error, stack);
    }
  }

  void _requestInvalidation() {
    ref.read(authInvalidationProvider.notifier).requestInvalidation();
  }
}
