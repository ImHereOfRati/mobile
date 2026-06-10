import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SliverMessageView extends StatelessWidget {
  final String message;
  final TextStyle style;
  final bool hasScrollBody;

  const SliverMessageView({
    super.key,
    required this.message,
    required this.style,
    this.hasScrollBody = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: hasScrollBody,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(message, style: style, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
