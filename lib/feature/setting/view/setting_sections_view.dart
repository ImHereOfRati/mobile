import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/view/my_info_view.dart';
import 'package:iamhere/feature/setting/view/setting_components.dart';
import 'package:iamhere/feature/setting/view/setting_diagnosis_section.dart';
import 'package:iamhere/feature/setting/view/setting_layout_components.dart';
import 'package:iamhere/feature/setting/view/setting_permission_section.dart';
import 'package:iamhere/feature/setting/view/setting_theme_toggle_item.dart';
import 'package:iamhere/feature/setting/view/setting_view_support.dart';
import 'package:iamhere/feature/setting/view/terms_view.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';

class SettingSectionsView extends ConsumerWidget {
  final SettingViewModelState state;

  const SettingSectionsView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h20Box = SizedBox(height: 20.h);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        SettingSection(
          title: '계정',
          items: [
            SettingItem(
              title: '내 정보',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyInfoView()),
              ),
            ),
          ],
        ),
        h20Box,
        SettingSection(title: '디스플레이', items: const [SettingThemeToggleItem()]),
        h20Box,
        SettingPermissionSection(state: state),
        h20Box,
        const SettingDiagnosisSection(),
        h20Box,
        SettingSection(
          title: '서비스 약관',
          items: [
            SettingItem(
              title: '약관 보기',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsView()),
              ),
            ),
          ],
        ),
        h20Box,
        SettingSection(
          title: '고객 지원',
          items: [
            SettingItem(
              title: '문의하기',
              onTap: () => SettingActionHandler.openSupportPage(context),
            ),
          ],
        ),
        h20Box,
        SettingSection(
          title: '앱 정보',
          items: [
            SettingItem(
              title: '버전 정보',
              trailingText: state.appVersion.isEmpty
                  ? '정보 없음'
                  : state.appVersion,
            ),
          ],
        ),
        SizedBox(height: 32.h),
        const SettingFooter(),
        SizedBox(height: 16.h),
        Center(
          child: TextButton(
            onPressed: () =>
                SettingActionHandler.handleWithdrawAccountTap(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '회원 탈퇴',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: cs.error,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }
}
