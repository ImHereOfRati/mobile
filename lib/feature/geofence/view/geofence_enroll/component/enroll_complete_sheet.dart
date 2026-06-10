import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

class EnrollCompleteSheet extends StatelessWidget {
  final String locationName;
  final EventType eventType;
  final List<Recipient> recipients;
  final bool isAutoSendReady;
  final VoidCallback onEnableAutoSend;
  final VoidCallback onCreateAnother;
  final VoidCallback onBackToMain;

  const EnrollCompleteSheet({
    super.key,
    required this.locationName,
    required this.eventType,
    required this.recipients,
    required this.isAutoSendReady,
    required this.onEnableAutoSend,
    required this.onCreateAnother,
    required this.onBackToMain,
  });

  String _buildSummaryText() {
    final recipient = recipients.isNotEmpty ? recipients.first.displayName : '수신자';
    final action = switch (eventType) {
      EventType.arrival => '도착하면',
      EventType.departure => '출발하면',
      EventType.both => '도착/출발하면',
    };
    return '$locationName에 $action\n$recipient에게 자동으로 알려드릴게요.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            '도착 알림이 저장되었어요!',
            style: AppTextStyles.gmarketBold(18, cs.onSurface),
          ),
          SizedBox(height: 16.h),

          // 요약 텍스트
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _buildSummaryText(),
              style: AppTextStyles.hannaAirRegular(14, cs.onSurface),
            ),
          ),
          SizedBox(height: 20.h),

          // 자동 전송 상태 가이드
          if (!isAutoSendReady)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '지금 바로 자동 전송을 켤 수 있어요.\n준비를 완료하면 도착하면 자동으로 연락을 보내드릴 거예요.',
                style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.72)),
              ),
            ),
          if (!isAutoSendReady) SizedBox(height: 20.h),

          // CTA 버튼들
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onEnableAutoSend,
              child: Text('자동 전송 켜기', style: AppTextStyles.hannaAirBold(14, cs.onPrimary)),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCreateAnother,
              child: Text('알림 더 만들기', style: AppTextStyles.hannaAirBold(14, cs.primary)),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onBackToMain,
              child: Text('메인으로 돌아가기', style: AppTextStyles.hannaAirRegular(14, cs.onSurface.withValues(alpha: 0.72))),
            ),
          ),
        ],
      ),
    );
  }
}
