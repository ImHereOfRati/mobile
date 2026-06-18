import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_feedback_handler.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/view/component/auth_hero_section.dart';
import 'package:iamhere/feature/auth/view/component/auth_info_components.dart';
import 'package:iamhere/feature/auth/view/component/auth_note_components.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model.dart';

class AuthView extends ConsumerStatefulWidget {
  final AuthViewModel _authViewModel;
  const AuthView(this._authViewModel, {super.key});

  static const _appTitle = 'ImHere';
  static const _heroSubtitle =
      '매번 연락하지 않아도 괜찮아요.\n처음 로그인 후 자동 전송 준비를 마치지 않으면 사용할 수 없어요.';

  static const _permissionSectionTitle = '이렇게 시작해요';
  static const _privacyNoteText = '내 위치는 기기 안에서만 처리돼요.\n외부 서버로는 전송되지 않아요.';
  static const _termsNoteText = '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.';
  static const _inactiveNotice = '현재 계정이 비활성 상태입니다. 운영자에게 문의하거나 다시 로그인해 주세요.';

  static const _permissionItems = [
    (Icons.edit_location_alt_outlined, '알림 만들기', '알림을 먼저 저장해요'),
    (
      Icons.notifications_active_outlined,
      '자동 전송',
      '처음 로그인 후 자동 전송 준비를 마치지 않으면 사용할 수 없어요',
    ),
    (Icons.dashboard_customize_outlined, '알림 관리', '메인에서 준비 상태를 바로 확인해요'),
  ];

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  Future<void> _handleProviderLogin(
    Future<Result<MemberState>> Function() loginAction,
  ) async {
    AppLogger.debug('AuthView: provider login started');
    final result = await loginAction();
    if (!mounted) return;
    result.handle(
      context: context,
      onSuccess: (loginResult) => _onLoginSuccess(loginResult),
      onFailure: (message) {
        AppLogger.warning('AuthView: provider login failed: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인에 실패했어요. 잠시 후 다시 시도해 주세요.'),
          ),
        );
      },
      showSnackBar: false,
    );
  }

  Future<void> _onLoginSuccess(MemberState loginResult) async {
    final redirectPath = GoRouterState.of(
      context,
    ).uri.queryParameters['redirect'];
    AppLogger.debug(
      'AuthView: login success state=$loginResult redirect=$redirectPath',
    );

    AppLogger.debug('AuthView: starting FCM sync after login');
    await widget._authViewModel.requestFCMTokenAndSendToServer();
    AppLogger.debug('AuthView: finished FCM sync after login');
    if (!mounted) return;
    ref.invalidate(authStateProvider);
    AppLogger.debug('AuthView: authStateProvider invalidated');

    if (loginResult == MemberState.existingUser &&
        redirectPath != null &&
        redirectPath.startsWith('/')) {
      AppLogger.debug('AuthView: navigating to redirect path=$redirectPath');
      context.go(redirectPath);
      return;
    }

    if ((loginResult == MemberState.pending ||
            loginResult == MemberState.newUser) &&
        redirectPath != null &&
        redirectPath.startsWith('/')) {
      AppLogger.debug(
        'AuthView: navigating to terms-consent with redirect=$redirectPath',
      );
      context.go(
        Uri(
          path: '/terms-consent',
          queryParameters: {'redirect': redirectPath},
        ).toString(),
      );
      return;
    }

    AppLogger.debug('AuthView: fallback navigate via MemberState.navigate');
    loginResult.navigate(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 2),
        const AuthHeroSection(
          appTitle: AuthView._appTitle,
          subtitle: AuthView._heroSubtitle,
        ),
        const Spacer(flex: 3),
        const AuthInfoCard(
          title: AuthView._permissionSectionTitle,
          items: AuthView._permissionItems,
        ),
        SizedBox(height: 12.h),
        const AuthPrivacyNote(text: AuthView._privacyNoteText),
        if (reason == 'inactive') ...[
          SizedBox(height: 12.h),
          _buildInactiveNotice(),
        ],
        SizedBox(height: 16.h),
        _buildLoginButton(),
        SizedBox(height: 12.h),
        const AuthTermsNote(text: AuthView._termsNoteText),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildLoginButton() {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _showProviderSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          '시작하기',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Future<void> _showProviderSheet() async {
    final cs = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '로그인 방식을 선택하세요',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                _ProviderOptionTile(
                  icon: Icons.g_mobiledata,
                  label: 'Google로 계속하기',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _handleProviderLogin(
                      widget._authViewModel.handleGoogleLogin,
                    );
                  },
                ),
                SizedBox(height: 12.h),
                _ProviderOptionTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Kakao로 계속하기',
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _handleProviderLogin(
                      widget._authViewModel.handleKakaoLogin,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInactiveNotice() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        AuthView._inactiveNotice,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 13.sp,
          color: cs.onErrorContainer,
        ),
      ),
    );
  }
}

class _ProviderOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProviderOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52.h,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Icon(icon, color: cs.onSurface),
                SizedBox(width: 12.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 15.sp,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
