import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../enroll_check_card.dart';
import '../fields/enroll_activate_toggle.dart';
import '../fields/enroll_message_field.dart';
import '../fields/enroll_name_field.dart';

class EnrollDetailsSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController messageController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;

  const EnrollDetailsSection({
    super.key,
    required this.nameController,
    required this.messageController,
    required this.isActive,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnrollNameField(controller: nameController),
        SizedBox(height: 20.h),
        EnrollMessageField(controller: messageController),
        SizedBox(height: 20.h),
        EnrollActivateToggle(
          isActive: isActive,
          onChanged: onActiveChanged,
        ),
        SizedBox(height: 12.h),
        const EnrollCheckCard(),
      ],
    );
  }
}
