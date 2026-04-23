import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/common/enroll_section_label.dart';

import 'radius_button.dart';
import 'radius_info_callout.dart';

const String _sectionRadius = '반경 설정';

class EnrollRadiusBlock extends StatelessWidget {
  final String selected;
  final String infoMessage;
  final ValueChanged<String> onChanged;

  const EnrollRadiusBlock({
    super.key,
    required this.selected,
    required this.infoMessage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const radii = [250, 500, 1000];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel(_sectionRadius),
        SizedBox(height: 10.h),
        Row(
          children: radii
              .map(
                (r) => RadiusButton(
                  radius: r,
                  isSelected: selected == '$r',
                  onTap: () => onChanged('$r'),
                ),
              )
              .toList(),
        ),
        if (infoMessage.isNotEmpty) ...[
          SizedBox(height: 10.h),
          RadiusInfoCallout(message: infoMessage),
        ],
      ],
    );
  }
}
