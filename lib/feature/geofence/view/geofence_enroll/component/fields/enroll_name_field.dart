import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/enroll_section_label.dart';

const String _sectionName = '위치 알람 이름';
const String _nameHint = '예) 우리집, 회사, 학교';

class EnrollNameField extends StatelessWidget {
  final TextEditingController controller;
  const EnrollNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel(_sectionName),
        SizedBox(height: 8.h),
        EnrollTextField(controller: controller, hint: _nameHint, maxLines: 1),
      ],
    );
  }
}
