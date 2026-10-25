import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

class SettingPermissionRow extends StatelessWidget {
  final String label;
  final bool granted;
  final VoidCallback onTap;

  const SettingPermissionRow({
    super.key,
    required this.label,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ImHereListRow(
      title: label,
      trailing: ImHereBadge(
        label: granted ? '허용됨' : '허용 안 됨',
        tone: granted ? ImHereBadgeTone.success : ImHereBadgeTone.warning,
        size: ImHereBadgeSize.medium,
      ),
      onTap: onTap,
    );
  }
}
