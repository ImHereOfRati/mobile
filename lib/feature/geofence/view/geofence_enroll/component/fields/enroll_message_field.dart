import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/enroll_section_label.dart';
import 'enroll_message_hint_banner.dart';

const String _sectionMessage = '도착 알림 메시지';
const String _messageHint = '안녕하세요! 서울시청에 도착했습니다.';

class EnrollMessageField extends StatelessWidget {
  final TextEditingController controller;
  const EnrollMessageField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel(_sectionMessage),
        SizedBox(height: 8.h),
        EnrollTextField(
          controller: controller,
          hint: _messageHint,
          maxLines: 3,
        ),
        SizedBox(height: 6.h),
        const EnrollMessageHintBanner(),
      ],
    );
  }
}
