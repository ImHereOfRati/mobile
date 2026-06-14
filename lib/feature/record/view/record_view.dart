import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';
import 'package:iamhere/feature/record/view_model/notification_view_model.dart';
import 'package:iamhere/feature/friend/view_model/friend_request_view_model.dart';

import 'component/record_overview_sections.dart';
import 'record_friend_requests_section.dart';
import 'record_notifications_section.dart';
import 'record_send_history_section.dart';

class RecordView extends ConsumerStatefulWidget {
  const RecordView({super.key});

  @override
  ConsumerState<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends ConsumerState<RecordView> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _refreshRecords);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _refreshRecords() {
    if (!mounted) return;
    ref.invalidate(geofenceRecordViewModelProvider);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final notificationsAsync = ref.watch(notificationViewModelProvider);
    final friendRequestsAsync = ref.watch(friendRequestViewModelProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: RecordPageHeader(count: recordsAsync.value?.length ?? 0)),
        RecordNotificationsSection(
          notificationsAsync: notificationsAsync,
          onViewAll: () => AppRoutes.goToRecordNotifications(context),
        ),
        RecordFriendRequestsSection(
          requestsAsync: friendRequestsAsync,
          onViewAll: () => AppRoutes.goToRecordFriendRequests(context),
        ),
        RecordSendHistorySection(
          recordsAsync: recordsAsync,
          ref: ref,
          onViewAll: () => AppRoutes.goToRecordSendHistory(context),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
