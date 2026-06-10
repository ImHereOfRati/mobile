import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

class GPSStatusBadge extends StatelessWidget {
  final bool isTracking;
  final bool isServiceDisabled;
  final Animation<double> animation;

  const GPSStatusBadge({
    super.key,
    required this.isTracking,
    required this.isServiceDisabled,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isTracking
            ? cs.primary
            : (isServiceDisabled ? cs.errorContainer : cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          _buildIcon(cs),
          SizedBox(width: 8.w),
          Text(
            _statusText,
            style: AppTextStyles.hannaAirBold(14, _foregroundColor(cs)),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ColorScheme cs) {
    final icon = Icon(
      isServiceDisabled ? Icons.location_off_outlined : Icons.location_on_outlined,
      color: _foregroundColor(cs),
      size: 20.sp,
    );

    if (isTracking) {
      return FadeTransition(opacity: animation, child: icon);
    }
    return icon;
  }

  String get _statusText {
    if (isServiceDisabled) return '위치 서비스가 꺼져 있어요';
    if (isTracking) return '자동 전송이 준비되어 있어요';
    return '자동 전송 준비가 필요해요';
  }

  Color _foregroundColor(ColorScheme cs) {
    if (isTracking) return cs.onPrimary;
    if (isServiceDisabled) return cs.error;
    return cs.onSurfaceVariant;
  }
}
