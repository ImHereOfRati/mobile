import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/auth/model/login_result.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/auth/view/component/login_button.dart';
import 'package:iamhere/auth/view/component/login_button_info.dart';
import 'package:iamhere/auth/view_model/auth_view_model.dart';
import 'package:iamhere/shared/base/result/result.dart';

const _permissionItems = [
  (Icons.notifications_outlined, '알림', '지오펜스 진입 시 알림'),
  (Icons.people_outline, '연락처', '수신자 선택에 사용'),
  (Icons.location_on_outlined, '위치', '백그라운드 위치 추적'),
];

class AuthView extends ConsumerStatefulWidget {
  final AuthViewModel _authViewModel;
  const AuthView(this._authViewModel, {super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  ColorScheme get _cs => Theme.of(context).colorScheme;

  // ── 로그인 로직 ───────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    final result = await widget._authViewModel.handleKakaoLogin();
    if (!mounted) return;
    result.handle(
      context: context,
      onSuccess: (loginResult) => _onLoginSuccess(loginResult),
      showSnackBar: false,
    );
  }

  Future<void> _onLoginSuccess(LoginResult loginResult) async {
    await widget._authViewModel.requestFCMTokenAndSendToServer();
    if (!mounted) return;
    ref.invalidate(authStateProvider);
    loginResult.navigate(context);
  }

  // ── 빌드 ─────────────────────────────────────────────────────────

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
        _buildHero(),
        const Spacer(flex: 3),
        _buildPermissionInfo(),
        SizedBox(height: 12.h),
        _buildPrivacyNote(),
        SizedBox(height: 16.h),
        _buildLoginButton(),
        SizedBox(height: 12.h),
        _buildTermsNote(),
        SizedBox(height: 32.h),
      ],
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 40.r, color: _cs.primary),
        SizedBox(height: 16.h),
        _buildHeroTitle(),
        SizedBox(height: 10.h),
        _buildHeroSubtitle(),
      ],
    );
  }

  Widget _buildHeroTitle() {
    return Text(
      'ImHere',
      style: TextStyle(
        fontFamily: 'GmarketSans',
        fontSize: 52.sp,
        fontWeight: FontWeight.w700,
        color: _cs.onSurface,
        letterSpacing: -0.5,
        height: 1.07,
      ),
    );
  }

  Widget _buildHeroSubtitle() {
    return Text(
      '정해진 장소를 지나면\n친구에게 자동으로 문자를 보내드릴게요.',
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 17.sp,
        color: _cs.onSurface.withValues(alpha: 0.7),
        letterSpacing: -0.374,
        height: 1.47,
      ),
    );
  }

  // ── 권한 안내 카드 ─────────────────────────────────────────────────

  Widget _buildPermissionInfo() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _cs.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPermissionHeader(),
          SizedBox(height: 12.h),
          ..._permissionItems.map(_buildPermissionRow),
        ],
      ),
    );
  }

  Widget _buildPermissionHeader() {
    return Text(
      '앱 사용에 필요한 권한',
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 12.sp,
        color: _cs.onSurface.withValues(alpha: 0.5),
        letterSpacing: -0.12,
      ),
    );
  }

  Widget _buildPermissionRow((IconData, String, String) item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(item.$1, size: 18.r, color: _cs.primary),
          SizedBox(width: 10.w),
          _buildPermissionLabel(item.$2),
          SizedBox(width: 8.w),
          _buildPermissionDesc(item.$3),
        ],
      ),
    );
  }

  Widget _buildPermissionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 14.sp,
        color: _cs.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.224,
      ),
    );
  }

  Widget _buildPermissionDesc(String desc) {
    return Text(
      desc,
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 13.sp,
        color: _cs.onSurface.withValues(alpha: 0.5),
        letterSpacing: -0.2,
      ),
    );
  }

  // ── 개인정보 안내 배너 ─────────────────────────────────────────────

  Widget _buildPrivacyNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 22.r, color: _cs.primary),
          SizedBox(width: 12.w),
          _buildPrivacyText(),
        ],
      ),
    );
  }

  Widget _buildPrivacyText() {
    return Expanded(
      child: Text(
        '내 위치는 기기 안에서만 처리돼요.\n외부 서버로는 전송되지 않아요.',
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 13.sp,
          color: _cs.onSurface.withValues(alpha: 0.85),
          letterSpacing: -0.2,
          height: 1.55,
        ),
      ),
    );
  }

  // ── 하단 버튼 / 안내 ───────────────────────────────────────────────

  Widget _buildLoginButton() {
    return LoginButton(
      buttonInfo: LoginInfoData.kakao,
      onPressed: _handleLogin,
    );
  }

  Widget _buildTermsNote() {
    return Text(
      '로그인 시 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 11.sp,
        color: _cs.onSurface.withValues(alpha: 0.35),
        letterSpacing: -0.12,
        height: 1.5,
      ),
    );
  }
}
