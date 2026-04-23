import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

import '../common/enroll_section_label.dart';
import 'enroll_message_hint_banner.dart';

const String _sectionMessage = '도착 알림 메시지';
const String _messageHint = '안녕하세요! {location}에 도착했습니다.';
const String _messageNote = '{location}은 위치 알람 이름으로 자동 변환돼요';

class EnrollMessageField extends StatelessWidget {
  final TextEditingController controller;
  const EnrollMessageField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        Text(
          _messageNote,
          style: AppTextStyles.hannaAirRegular(
            12,
            cs.onSurface.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: 8.h),
        const EnrollMessageHintBanner(),
      ],
    );
  }
}
