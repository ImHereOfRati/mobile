import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';

import 'component/notification_overview_item.dart';
import 'component/record_empty_section.dart';
import 'component/record_section_header.dart';

class RecordNotificationsSection extends StatelessWidget {
  final AsyncValue<List<NotificationEntity>> notificationsAsync;
  final VoidCallback onViewAll;

  const RecordNotificationsSection({
    super.key,
    required this.notificationsAsync,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '받은 알림',
            unreadCount: notificationsAsync.value?.length ?? 0,
            onViewAll: onViewAll,
          ),
        ),
        notificationsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: RecordEmptySection(message: '알림을 불러올 수 없습니다'),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const SliverToBoxAdapter(
                child: RecordEmptySection(message: '받은 알림이 없습니다'),
              );
            }
            final preview = notifications.take(3).toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => NotificationOverviewItem(
                  notification: preview[index],
                ),
                childCount: preview.length,
              ),
            );
          },
        ),
      ],
    );
  }
}
