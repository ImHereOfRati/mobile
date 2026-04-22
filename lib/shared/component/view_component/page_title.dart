import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class PageTitle extends StatelessWidget {
  final String title;
  final String description;
  final String infoCount;
  final List<Widget> actions;
  final double bottomSpacing;

  const PageTitle({
    super.key,
    required this.title,
    required this.description,
    required this.infoCount,
    this.actions = const [],
    this.bottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageTitle(colorScheme),
            SizedBox(height: 2.h),

            _buildPageDescription(colorScheme),
            SizedBox(height: 4.h),

            _buildInfoCount(colorScheme),

            if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
            if (actions.isNotEmpty) ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle(ColorScheme colorScheme) {
    return Text(title, style: AppTextStyles.bigBlackTitle(colorScheme));
  }

  Widget _buildPageDescription(ColorScheme colorScheme) {
    return Text(
      description,
      style: AppTextStyles.smallGreyDescription(colorScheme),
    );
  }

  Widget _buildInfoCount(ColorScheme colorScheme) {
    return Text(
      infoCount,
      style: AppTextStyles.smallBlueDescription(colorScheme),
    );
  }
}
