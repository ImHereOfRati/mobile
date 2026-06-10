import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

import 'enroll_complete_actions.dart';
import 'enroll_complete_status_banner.dart';
import 'enroll_complete_summary_card.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = switch (eventType) {
      EventType.arrival => '도착 알림이 저장되었어요!',
      EventType.departure => '출발 알림이 저장되었어요!',
      EventType.both => '도착/출발 알림이 저장되었어요!',
    };

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
          Text(
            title,
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: 16.h),

          EnrollCompleteSummaryCard(
            locationName: locationName,
            eventType: eventType,
            recipients: recipients,
          ),
          SizedBox(height: 20.h),

          EnrollCompleteStatusBanner(isAutoSendReady: isAutoSendReady),
          SizedBox(height: 20.h),

          EnrollCompleteActions(
            isAutoSendReady: isAutoSendReady,
            onEnableAutoSend: onEnableAutoSend,
            onCreateAnother: onCreateAnother,
            onBackToMain: onBackToMain,
          ),
        ],
      ),
    );
  }
}
