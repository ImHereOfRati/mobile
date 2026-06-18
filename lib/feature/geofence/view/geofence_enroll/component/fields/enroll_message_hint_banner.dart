import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

class EnrollMessageHintBanner extends StatelessWidget {
  final String locationName;
  final String locationAddress;
  final String senderName;
  final EventType eventType;
  final String message;
  final List<Recipient> recipients;

  const EnrollMessageHintBanner({
    super.key,
    required this.locationName,
    required this.locationAddress,
    required this.senderName,
    required this.eventType,
    required this.message,
    required this.recipients,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final hasSms = recipients.any((r) => r is LocalRecipient);
    final hasFcmOnly = recipients.isNotEmpty && !hasSms;
    final noRecipient = recipients.isEmpty;

    final location = composeFullLocation(
      locationName,
      locationAddress,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(cs, hasSms, hasFcmOnly, noRecipient),
          SizedBox(height: 10.h),
          if (noRecipient) ...[
            _buildNoRecipientGuide(cs),
          ] else if (hasFcmOnly) ...[
            _buildFcmNote(cs),
          ] else ...[
            _buildSmsPreview(cs, location),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    ColorScheme cs,
    bool hasSms,
    bool hasFcmOnly,
    bool noRecipient,
  ) {
    IconData icon;
    String title;
    Color color;

    if (noRecipient) {
      icon = Icons.info_outline;
      title = '수신자 선택 대기 중';
      color = cs.tertiary;
    } else if (hasFcmOnly) {
      icon = Icons.notifications_active_outlined;
      title = 'FCM 푸시 알림';
      color = cs.primary;
    } else {
      icon = Icons.sms_outlined;
      title = 'SMS 문자 발송 (45자 제한)';
      color = cs.error;
    }

    return Row(
      children: [
        Icon(icon, size: 16.r, color: color),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.hannaAirBold(12, color),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRecipientGuide(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        '수신자를 추가하시면 발송 방식(문자 또는 푸시 알림)에 맞춰 실시간 미리보기가 제공됩니다.',
        style: AppTextStyles.hannaAirRegular(
          12,
          cs.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildFcmNote(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, size: 14.r, color: cs.primary),
              SizedBox(width: 4.w),
              Text(
                'FCM 푸시 알림은 저장 후 자동 전송돼요',
                style: AppTextStyles.hannaAirBold(11, cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmsPreview(ColorScheme cs, String location) {
    final body = composeSmsBody(
      eventType: eventType,
      message: message,
      location: location,
    );
    final preview = composeSmsPreview(
      eventType: eventType,
      message: message,
      location: location,
    );
    final isOverLimit = body.length > smsBodyMaxLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isOverLimit
                  ? cs.error.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sms, size: 14.r, color: cs.onSurfaceVariant),
                  SizedBox(width: 4.w),
                  Text(
                    'SMS 문자 발신 미리보기',
                    style: AppTextStyles.hannaAirBold(11, cs.onSurfaceVariant),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(preview, style: AppTextStyles.hannaAirRegular(12, cs.onSurface)),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'SMS 본문 ${body.length}/$smsBodyMaxLength',
          style: AppTextStyles.hannaAirRegular(
            11,
            isOverLimit ? cs.error : cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        if (isOverLimit) ...[
          SizedBox(height: 4.h),
          Text(
            'SMS 본문이 45자를 넘으면 저장할 수 없어요.',
            style: AppTextStyles.hannaAirRegular(11, cs.error),
          ),
        ],
        SizedBox(height: 6.h),
        Text(
          '예: 이름은 "${senderName.trim().isEmpty ? '홍길동' : senderName.trim()}", 장소는 "우리집 (서울 강남구)"처럼 적어 주세요.',
          style: AppTextStyles.hannaAirRegular(
            11,
            cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
