import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

class EnrollCompleteActions extends StatelessWidget {
  final bool isAutoSendReady;
  final VoidCallback onEnableAutoSend;
  final VoidCallback onCreateAnother;
  final VoidCallback onBackToMain;

  const EnrollCompleteActions({
    super.key,
    required this.isAutoSendReady,
    required this.onEnableAutoSend,
    required this.onCreateAnother,
    required this.onBackToMain,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (!isAutoSendReady) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onEnableAutoSend,
              child: Text('자동 전송 켜기', style: AppTextStyles.hannaAirBold(14, cs.onPrimary)),
            ),
          ),
          SizedBox(height: 10.h),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCreateAnother,
            child: Text('알림 더 만들기', style: AppTextStyles.hannaAirBold(14, cs.primary)),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onBackToMain,
            child: Text('메인으로 돌아가기', style: AppTextStyles.hannaAirRegular(14, cs.onSurface.withValues(alpha: 0.72))),
          ),
        ),
      ],
    );
  }
}
