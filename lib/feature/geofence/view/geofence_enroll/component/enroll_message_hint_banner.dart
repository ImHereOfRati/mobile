import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _smsNote = '문자 메시지 발송 시에는 적용되지 않아요';

class EnrollMessageHintBanner extends StatelessWidget {
  const EnrollMessageHintBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.sms_outlined, size: 16.r, color: cs.tertiary),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _smsNote,
              style: AppTextStyles.hannaAirBold(12, cs.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}
