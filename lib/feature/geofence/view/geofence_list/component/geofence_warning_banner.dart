import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class GeofenceWarningBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const GeofenceWarningBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: _buildContent(cs),
        ),
      ),
    );
  }

  Row _buildContent(ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: cs.onSurface),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.hannaAirBold(12, cs.onSurface),
          ),
        ),
        Icon(Icons.chevron_right, size: 18.sp, color: cs.onSurface),
      ],
    );
  }
}
