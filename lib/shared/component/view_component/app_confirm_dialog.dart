import 'package:flutter/material.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final Color? confirmTextColor;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = '취소',
    this.confirmText = '확인',
    this.confirmTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title, style: AppTextStyles.gSansBold(18, cs.onSurface)),
      content: Text(
        content,
        style: AppTextStyles.hannaAirRegular(14, cs.onSurface),
      ),
      actions: [
        _buildCancelButton(context, cs),
        _buildConfirmButton(context, cs),
      ],
    );
  }

  TextButton _buildConfirmButton(BuildContext context, ColorScheme cs) {
    return TextButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text(
        confirmText,
        style: AppTextStyles.hannaAirMedium(14, confirmTextColor ?? cs.primary),
      ),
    );
  }

  TextButton _buildCancelButton(BuildContext context, ColorScheme cs) {
    return TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: Text(
        cancelText,
        style: AppTextStyles.hannaAirMedium(14, cs.primary),
      ),
    );
  }
}
