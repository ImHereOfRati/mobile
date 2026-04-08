import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/model/login_result.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
import 'package:iamhere/auth/view/component/login_button.dart';
import 'package:iamhere/auth/view/component/login_button_info.dart';
import 'package:iamhere/auth/view/component/right_content_widget.dart';
import 'package:iamhere/auth/view_model/auth_view_model.dart';
import 'package:iamhere/common/result/result.dart';
import 'package:iamhere/core/di/di_setup.dart';

class AuthView extends ConsumerStatefulWidget {
  final AuthViewModel _authViewModel;
  const AuthView(this._authViewModel, {super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  final String _appTitle = 'ImHere';
  final String _subTitle = '정해진 장소를 지나면 문자를 보낼게요!';
  final String _authorizationRequestDescription = '앱 사용을 위해 다음 권한이 필요해요';
  final List<String> _authorizationElements = ['알람', '연락처', '위치'];

  /// 로그인 처리 로직
  Future<void> _handleLogin() async {
    var result = await widget._authViewModel.handleKakaoLogin();

    if (!mounted) return;

    // 로그인 결과 처리 및 분기 로직
    result.handle(
      context: context,
      onSuccess: (loginResult) {
        if (!mounted) return;

        // 신규 사용자: 약관 동의 화면으로 이동
        if (loginResult == LoginResult.newUser) {
          context.go('/terms-consent');
          return;
        }

        // 기존 사용자: FCM 토큰 전송 후 메인 화면으로 이동
        _sendFcmTokenAndNavigateToMain();
      },
      showSnackBar: false,
    );
  }

  /// FCM 토큰 서버 전송 및 메인 화면 이동
  Future<void> _sendFcmTokenAndNavigateToMain() async {
    final tokenStorage = getIt<TokenStorageService>();
    final accessToken = await tokenStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty && mounted) {
      var fcmResult = await widget._authViewModel
          .requestFCMTokenAndSendToServer();

      if (!mounted) return;

      fcmResult.handle(
        context: context,
        onSuccess: (data) {
          if (mounted) {
            // authStateProvider를 invalidate하여 최신 인증 상태 반영
            // GoRouter의 redirect 로직이 자동으로 /geofence로 이동시킴
            ref.invalidate(authStateProvider);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 65.h),
            buildAppTitle(context),
            SizedBox(height: 6.h),
            buildAppSubTitle(context),
            SizedBox(height: 270.h),
            consistLoginButtons(context),
            SizedBox(height: 40.h),
            buildAuthorizationRequestDescription(context),
            SizedBox(height: 10.h),
            consistAuthenticationElements(context),
          ],
        ),
      ),
    );
  }

  Text buildAppTitle(BuildContext context) {
    return Text(
      _appTitle,
      style: Theme.of(
        context,
      ).textTheme.headlineLarge?.copyWith(fontSize: 58.sp),
    );
  }

  Text buildAppSubTitle(BuildContext context) {
    return Text(
      _subTitle,
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontSize: 20.sp),
    );
  }

  Widget consistLoginButtons(BuildContext context) {
    return Column(
      children: [
        LoginButton(
          buttonInfo: LoginInfoData.kakao,
          onPressed: () async {
            await _handleLogin();
          },
        ),
      ],
    );
  }

  Text buildAuthorizationRequestDescription(BuildContext context) {
    return Text(
      _authorizationRequestDescription,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Row consistAuthenticationElements(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _authorizationElements
          .map((right) => rightContentWidget(context: context, right: right))
          .toList(),
    );
  }
}
