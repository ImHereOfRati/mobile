import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/auth/view/component/login_button.dart';
import 'package:iamhere/auth/view/component/login_button_info.dart';
import 'package:iamhere/auth/view_model/auth_view_model.dart';
import 'package:iamhere/shared/base/result/result.dart';

class AuthView extends ConsumerStatefulWidget {
  final AuthViewModel _authViewModel;
  const AuthView(this._authViewModel, {super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  Future<void> _handleLogin() async {
    final result = await widget._authViewModel.handleKakaoLogin();
    if (!mounted) return;

    result.handle(
      context: context,
      onSuccess: (_) async {
        if (!mounted) return;
        await widget._authViewModel.requestFCMTokenAndSendToServer();
        if (!mounted) return;
        ref.invalidate(authStateProvider);
        context.go('/terms-consent');
      },
      showSnackBar: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              _buildHero(),
              const Spacer(flex: 3),
              _buildPermissionInfo(),
              SizedBox(height: 24.h),
              _buildLoginButton(),
              SizedBox(height: 16.h),
              _buildTermsNote(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          size: 40.r,
          color: const Color(0xFF0071E3),
        ),
        SizedBox(height: 16.h),
        Text(
          'ImHere',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 52.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.07,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          '정해진 장소를 지나면\n친구에게 자동으로 문자를 보내드릴게요.',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 17.sp,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: -0.374,
            height: 1.47,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionInfo() {
    final items = [
      (Icons.notifications_outlined, '알림', '지오펜스 진입 시 알림'),
      (Icons.people_outline, '연락처', '수신자 선택에 사용'),
      (Icons.location_on_outlined, '위치', '백그라운드 위치 추적'),
    ];

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '앱 사용에 필요한 권한',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 12.h),
          ...items.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  Icon(e.$1, size: 18.r, color: const Color(0xFF0071E3)),
                  SizedBox(width: 10.w),
                  Text(
                    e.$2,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.224,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    e.$3,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 13.sp,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        color: Colors.white.withValues(alpha: 0.35),
        letterSpacing: -0.12,
        height: 1.5,
      ),
    );
  }
}
