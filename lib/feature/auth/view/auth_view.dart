import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:iamhere/feature/auth/view/component/auth_hero_section.dart';
import 'package:iamhere/feature/auth/view/component/auth_info_components.dart';
import 'package:iamhere/feature/auth/view/component/auth_note_components.dart';
import 'package:iamhere/feature/auth/view/component/login_button.dart';
import 'package:iamhere/feature/auth/view/component/login_button_info.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model.dart';
import 'package:iamhere/common/base/result/result_feedback_handler.dart';

class AuthView extends ConsumerStatefulWidget {
  final AuthViewModel _authViewModel;
  const AuthView(this._authViewModel, {super.key});

  static const _appTitle = 'ImHere';
  static const _heroSubtitle = '매번 연락하지 않아도 괜찮아요.\n도착하면 원하는 사람에게 자동으로 알려드릴게요.';

  static const _permissionSectionTitle = '이렇게 시작해요';
  static const _privacyNoteText = '내 위치는 기기 안에서만 처리돼요.\n외부 서버로는 전송되지 않아요.';
  static const _termsNoteText = '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.';

  static const _permissionItems = [
    (Icons.edit_location_alt_outlined, '알림 만들기', '도착 알림을 먼저 저장해요'),
    (Icons.notifications_active_outlined, '자동 전송', '필요할 때만 준비를 마치면 돼요'),
    (Icons.dashboard_customize_outlined, '알림 관리', '메인에서 준비 상태를 바로 확인해요'),
  ];

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  Future<void> _handleLogin() async {
    final result = await widget._authViewModel.handleKakaoLogin();
    if (!mounted) return;
    result.handle(
      context: context,
      onSuccess: (loginResult) => _onLoginSuccess(loginResult),
      showSnackBar: false,
    );
  }

  Future<void> _onLoginSuccess(MemberState loginResult) async {
    await widget._authViewModel.requestFCMTokenAndSendToServer();
    if (!mounted) return;
    ref.invalidate(authStateProvider);
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
        SizedBox(height: 16.h),
        _buildLoginButton(),
        SizedBox(height: 12.h),
        const AuthTermsNote(text: AuthView._termsNoteText),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildLoginButton() {
    return LoginButton(
      buttonInfo: LoginInfoData.kakao,
      onPressed: _handleLogin,
    );
  }
}
