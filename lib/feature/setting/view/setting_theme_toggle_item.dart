import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/theme/theme_mode_provider.dart';

class SettingThemeToggleItem extends ConsumerWidget {
  const SettingThemeToggleItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = ref.watch(
      appThemeModeProvider.select((m) => m == ThemeMode.dark),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 20.r,
            color: cs.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '다크 모드',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 16.sp,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: cs.primary,
            onChanged: (_) => ref.read(appThemeModeProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}
