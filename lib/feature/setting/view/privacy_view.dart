import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/const/policy_data.dart';

class PrivacyView extends StatelessWidget {
  final String title;
  const PrivacyView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: _buildPageContentsWidgets(context),
      ),
    );
  }

  Text _buildPageContentsWidgets(BuildContext context) {
    return Text(
      _decidePageContents(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.5,
        fontSize: 18.sp,
      ),
    );
  }

  String _decidePageContents() {
    return title == '개인정보 보호 정책'
        ? PolicyData.privacyPolicy
        : title == '서비스 이용약관'
        ? PolicyData.termsOfService
        : '내용을 불러올 수 없습니다.';
  }
}
