import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';

import '../common/enroll_section_label.dart';
import 'enroll_message_hint_banner.dart';

const String _sectionMessage = '보낼 메시지 (선택)';
const String _messageHint = '비워두면 기본 메시지를 자동으로 보내드려요';

class EnrollMessageField extends StatelessWidget {
  final TextEditingController controller;
  final EventType eventType;

  const EnrollMessageField({
    super.key,
    required this.controller,
    required this.eventType,
  });

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
        EnrollMessageHintBanner(eventType: eventType),
      ],
    );
  }
}
