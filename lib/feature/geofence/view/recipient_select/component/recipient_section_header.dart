import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

class RecipientSectionHeader extends StatelessWidget {
  final String title;

  const RecipientSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      color: cs.onSurface.withValues(alpha: 0.04),
      child: Text(
        title,
        style: AppTextStyles.hannaAirBold(
          13,
          cs.onSurface.withValues(alpha: 0.6),
        ).copyWith(letterSpacing: -0.2),
      ),
    );
  }
}
