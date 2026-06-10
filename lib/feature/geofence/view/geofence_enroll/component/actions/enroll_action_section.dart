import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../enroll_save_button.dart';

class EnrollActionSection extends StatelessWidget {
  final VoidCallback onSave;

  const EnrollActionSection({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EnrollSaveButton(onPressed: onSave),
        SizedBox(height: 16.h),
      ],
    );
  }
}
