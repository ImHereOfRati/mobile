import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthPrivacyNote extends StatelessWidget {
  final String text;

  const AuthPrivacyNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 22.r, color: cs.primary),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                color: cs.onSurface.withValues(alpha: 0.85),
                letterSpacing: -0.2,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTermsNote extends StatelessWidget {
  final String text;

  const AuthTermsNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'BMHANNAAir',
        fontSize: 11.sp,
        color: cs.onSurface.withValues(alpha: 0.35),
        letterSpacing: -0.12,
        height: 1.5,
      ),
    );
  }
}
