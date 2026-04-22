import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _emojiKey = '🔑';
const String _checkCardTitle = '꼭 확인하세요!';
const String _checkCardContent = '위치 알람을 등록한 후에는 반드시 활성화를 해야 알림이 전송됩니다. 메인 화면에서 스위치를 켜주세요!';

class EnrollCheckCard extends StatelessWidget {
  const EnrollCheckCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      padding: EdgeInsets.all(14.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_emojiKey, style: AppTextStyles.hannaAirRegular(16, cs.onSurface)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _checkCardTitle,
                  style: AppTextStyles.hannaAirBold(13, cs.tertiary),
                ),
                SizedBox(height: 4.h),
                Text(
                  _checkCardContent,
                  style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.7)).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

