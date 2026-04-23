import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class EnrollSectionLabel extends StatelessWidget {
  final String title;
  const EnrollSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: AppTextStyles.gSansBold(
        16,
        cs.onSurface,
      ).copyWith(letterSpacing: -0.2),
    );
  }
}

class EnrollTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const EnrollTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.hannaAirRegular(14, cs.onSurface),
        decoration: _buildInputDecoration(cs),
      ),
    );
  }

  InputDecoration _buildInputDecoration(ColorScheme cs) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hannaAirRegular(
        14,
        cs.onSurface.withValues(alpha: 0.35),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    );
  }
}
