import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

class EnrollCompleteStatusBanner extends StatelessWidget {
  final bool isAutoSendReady;

  const EnrollCompleteStatusBanner({super.key, required this.isAutoSendReady});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isAutoSendReady ? cs.primary.withValues(alpha: 0.08) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        isAutoSendReady
            ? '자동 전송 준비가 완료되어 있어요.\n별도 설정 없이 자동으로 연락을 보내드려요.'
            : '지금 바로 자동 전송을 켤 수 있어요.\n준비를 완료하면 자동으로 연락을 보내드릴 거예요.',
        style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.72)),
      ),
    );
  }
}
