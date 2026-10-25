import 'package:flutter/material.dart';

class BackgroundLocationDisclosureDetails extends StatelessWidget {
  const BackgroundLocationDisclosureDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '앱을 닫아도 위치 정보를 수집해요.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '등록한 장소에 도착하거나 떠날 때, 선택한 친구에게 알려요.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
