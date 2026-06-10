import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class SendRecordOverviewItem extends StatelessWidget {
  final GeofenceRecordEntity record;

  const SendRecordOverviewItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recipient = RecordTimeFormatter.formatRecipients(record.recipients);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: _cardDecoration(cs),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.location_on_rounded, color: cs.primary, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.geofenceName, style: tt.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text('$recipient에게 전송 완료', style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(RecordTimeFormatter.formatRelativeTime(record.createdAt), style: tt.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class FriendRequestOverviewItem extends StatelessWidget {
  final ReceivedFriendRequestResponseDto request;

  const FriendRequestOverviewItem({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => AppRoutes.goToRecordFriendRequests(context),
      child: _BaseOverviewItem(
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          child: Text(
            request.requesterNickname.isNotEmpty ? request.requesterNickname[0] : '?',
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        title: request.requesterNickname,
        subtitle: request.requesterEmail,
        titleStyle: tt.headlineSmall,
        subtitleStyle: tt.bodyMedium,
      ),
    );
  }
}

class NotificationOverviewItem extends StatelessWidget {
  final NotificationEntity notification;

  const NotificationOverviewItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => AppRoutes.goToRecordNotifications(context),
      child: _BaseOverviewItem(
        leading: Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.notifications_rounded, color: cs.primary, size: 20.r),
        ),
        title: notification.title,
        subtitle: notification.body,
        trailing: Text(
          RecordTimeFormatter.formatRelativeTime(notification.createdAt),
          style: tt.bodySmall,
        ),
        titleStyle: tt.headlineSmall,
        subtitleStyle: tt.bodyMedium,
      ),
    );
  }
}

class _BaseOverviewItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;

  const _BaseOverviewItem({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Container(
        decoration: _cardDecoration(cs),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              leading,
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(subtitle, style: subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8.w),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(12.r),
    boxShadow: [
      BoxShadow(
        color: cs.onSurface.withValues(alpha: 0.06),
        offset: const Offset(0, 2),
        blurRadius: 12,
      ),
    ],
  );
}

class RecordTimeFormatter {
  static String formatRecipients(String recipientsJson) {
    try {
      final list = jsonDecode(recipientsJson) as List<dynamic>;
      if (list.isEmpty) return '수신자';
      if (list.length == 1) return list.first as String;
      return '${list.first} 외 ${list.length - 1}명';
    } catch (_) {
      return '수신자';
    }
  }

  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${dt.month}월 ${dt.day}일';
  }
}
