import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/enroll_section_label.dart';
import '../radius/enroll_radius_section.dart';

const String _sectionPlace = '어디에서 알려드릴까요?';

class EnrollLocationSection extends StatelessWidget {
  final Widget mapSection;
  final String selectedRadius;
  final String radiusInfoMessage;
  final ValueChanged<String> onRadiusChanged;

  const EnrollLocationSection({
    super.key,
    required this.mapSection,
    required this.selectedRadius,
    required this.radiusInfoMessage,
    required this.onRadiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel(_sectionPlace),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: mapSection,
        ),
        SizedBox(height: 20.h),
        EnrollRadiusBlock(
          selected: selectedRadius,
          infoMessage: radiusInfoMessage,
          onChanged: onRadiusChanged,
        ),
      ],
    );
  }
}
