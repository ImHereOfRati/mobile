import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const SettingSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 16.w,
                      color: Theme.of(context).dividerTheme.color,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class SettingFooter extends StatelessWidget {
  const SettingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            'Imhere © 2025',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '도착 알림 자동 연락 서비스',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
        ],
      ),
    );
  }
}
