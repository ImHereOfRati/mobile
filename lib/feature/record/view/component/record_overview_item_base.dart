import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'record_card_decoration.dart';

class RecordOverviewItemBase extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final Widget? footer;
  final int subtitleMaxLines;

  const RecordOverviewItemBase({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.trailing,
    this.footer,
    this.subtitleMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: recordCardDecoration(cs),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              leading,
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: subtitleStyle,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (footer != null) ...[
                      SizedBox(height: 6.h),
                      footer!,
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8.w),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
