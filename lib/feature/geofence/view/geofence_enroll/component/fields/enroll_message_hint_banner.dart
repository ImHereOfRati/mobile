import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';

const String _smsNote = '문자 메시지 발송 시에는 적용되지 않아요\n대신 아래와 같이 발송됩니다.';
const String _smsExample =
    '[Web발신]\n{장소 이름} (도로명 주소)에 안전하게 도착하였습니다.\n\n보낸 분 : {사용자 닉네임}\n시간: {도착 시간}\nService by ImHere\n';

class EnrollMessageHintBanner extends StatelessWidget {
  final EventType eventType;

  const EnrollMessageHintBanner({super.key, required this.eventType});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hintTitle(cs),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _buildSmsExample(),
              style: AppTextStyles.hannaAirRegular(12, cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Row _hintTitle(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.sms_outlined, size: 16.r, color: cs.tertiary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            _smsNote,
            style: AppTextStyles.hannaAirBold(12, cs.tertiary),
          ),
        ),
      ],
    );
  }

  String _buildSmsExample() {
    switch (eventType) {
      case EventType.departure:
        return _smsExample.replaceFirst('안전하게 도착하였습니다.', '안전하게 출발하였습니다.');
      case EventType.both:
        return _smsExample.replaceFirst(
          '안전하게 도착하였습니다.',
          '도착/출발 알림을 자동으로 전송합니다.',
        );
      case EventType.arrival:
        return _smsExample;
    }
  }
}
