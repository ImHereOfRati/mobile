import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

class EnrollCompleteSummaryCard extends StatelessWidget {
  final String locationName;
  final EventType eventType;
  final List<Recipient> recipients;

  const EnrollCompleteSummaryCard({
    super.key,
    required this.locationName,
    required this.eventType,
    required this.recipients,
  });

  String _summaryText() {
    final recipient = recipients.isNotEmpty ? recipients.first.displayName : '수신자';
    final others = recipients.length > 1 ? ' 외 ${recipients.length - 1}명' : '';
    final action = switch (eventType) {
      EventType.arrival => '도착하면',
      EventType.departure => '출발하면',
      EventType.both => '도착/출발하면',
    };
    return '$locationName에 $action\n$recipient$others에게 자동으로 알려드릴게요.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        _summaryText(),
        style: AppTextStyles.hannaAirRegular(14, cs.onSurface),
      ),
    );
  }
}
