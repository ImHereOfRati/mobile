import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _mapHint = '지도에서 위치를 선택하세요';

class EnrollMapHintOverlay extends StatelessWidget {
  const EnrollMapHintOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: cs.scrim.withValues(alpha: 0.18),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, size: 40.r, color: cs.primary),
                SizedBox(height: 8.h),
                Text(
                  _mapHint,
                  style: AppTextStyles.hannaAirBold(14, cs.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
