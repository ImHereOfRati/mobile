import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthHeroSection extends StatelessWidget {
  final String appTitle;
  final String subtitle;

  const AuthHeroSection({
    super.key,
    required this.appTitle,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.location_on, size: 40.r, color: cs.primary),
        SizedBox(height: 16.h),
        Text(
          appTitle,
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 52.sp,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: -0.5,
            height: 1.07,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 17.sp,
            color: cs.onSurface.withValues(alpha: 0.7),
            letterSpacing: -0.374,
            height: 1.47,
          ),
        ),
      ],
    );
  }
}
