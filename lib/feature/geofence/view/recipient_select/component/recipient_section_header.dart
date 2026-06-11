import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

class RecipientSectionHeader extends StatelessWidget {
  final String title;

  const RecipientSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 12.h),
      child: Text(
        title,
        style: AppTextStyles.hannaAirBold(
          14,
          cs.onSurface.withValues(alpha: 0.7),
        ).copyWith(letterSpacing: -0.3),
      ),
    );
  }
}
