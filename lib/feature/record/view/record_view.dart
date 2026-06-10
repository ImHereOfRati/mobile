import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';
import 'package:iamhere/feature/record/view_model/notification_view_model.dart';
import 'package:iamhere/feature/friend/view_model/friend_request_view_model.dart';

import 'component/record_overview_items.dart';
import 'component/record_overview_sections.dart';

class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final notificationsAsync = ref.watch(notificationViewModelProvider);
    final friendRequestsAsync = ref.watch(friendRequestViewModelProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: RecordPageHeader(count: recordsAsync.value?.length ?? 0),
        ),

        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '받은 알림',
            unreadCount: notificationsAsync.value?.length ?? 0,
            onViewAll: () => AppRoutes.goToRecordNotifications(context),
          ),
        ),
        notificationsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: const RecordEmptySection(message: '알림을 불러올 수 없습니다'),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return SliverToBoxAdapter(
                child: const RecordEmptySection(message: '받은 알림이 없습니다'),
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

        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '받은 친구 요청',
            unreadCount: friendRequestsAsync.value?.length ?? 0,
            onViewAll: () => AppRoutes.goToRecordFriendRequests(context),
          ),
        ),
        friendRequestsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: const RecordEmptySection(message: '친구 요청을 불러올 수 없습니다'),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return SliverToBoxAdapter(
                child: const RecordEmptySection(message: '받은 친구 요청이 없습니다'),
              );
            }
            final preview = requests.take(3).toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => FriendRequestOverviewItem(
                  request: preview[index],
                ),
                childCount: preview.length,
              ),
            );
          },
        ),

        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '나의 전송 기록',
            unreadCount: recordsAsync.value?.length ?? 0,
            onViewAll: () => AppRoutes.goToRecordSendHistory(context),
          ),
        ),

        recordsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverToBoxAdapter(
            child: RecordErrorSection(ref: ref),
          ),
          data: (records) {
            if (records.isEmpty) {
              return SliverToBoxAdapter(
                child: const RecordEmptySection(message: '전송된 기록이 없습니다'),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SendRecordOverviewItem(
                  record: records[index],
                ),
                childCount: records.length,
              ),
            );
          },
        ),

        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }
}
