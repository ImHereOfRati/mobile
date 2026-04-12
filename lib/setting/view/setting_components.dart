import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/view_component/widgets/section_title.dart';

class SettingSectionHeader extends StatelessWidget {
  final String title;

  const SettingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SectionTitle(title: title),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final String? trailingText;
  final bool isDestructive;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.title,
    this.trailingText,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      trailing: trailingText != null
          ? Text(
              trailingText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF48D1CC), // Primary Color
                fontWeight: FontWeight.w500,
              ),
            )
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
