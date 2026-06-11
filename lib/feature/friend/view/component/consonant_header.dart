import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConsonantHeader extends StatelessWidget {
  final String consonant;

  const ConsonantHeader({required this.consonant, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consonant,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 6.h),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: cs.onSurface.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}
