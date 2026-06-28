import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

import 'record_overview_item_base.dart';
import 'record_time_formatter.dart';

class NotificationOverviewItem extends StatelessWidget {
  final NotificationEntity notification;

  const NotificationOverviewItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => AppRoutes.goToNotificationDetail(context, notification),
      child: RecordOverviewItemBase(
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
        trailing: Text(RecordTimeFormatter.formatRelativeTime(notification.createdAt), style: tt.bodySmall),
        titleStyle: tt.headlineSmall,
        subtitleStyle: tt.bodyMedium,
      ),
    );
  }
}
