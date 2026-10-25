import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/date_time_formatter.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:iamhere/feature/record/view/widget/activity_card.dart';
import 'package:iamhere/feature/record/view/widget/activity_section.dart';
import 'package:iamhere/feature/record/viewmodel/record_overview_view_model.dart';

/// 기록 탭의 첫 화면. 받은 알림, 친구 요청, 전송 기록의 최근 항목을 한눈에 보여 준다.
class RecordPage extends ConsumerStatefulWidget {
  final ActivityLogService activityLog;
  final FriendService friendService;

  const RecordPage({
    super.key,
    required this.activityLog,
    required this.friendService,
  });

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage>
    with WidgetsBindingObserver {
  RecordOverviewViewModelProvider get _provider =>
      recordOverviewViewModelProvider(widget.activityLog, widget.friendService);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 알림과 친구 요청은 앱 밖에서 쌓이므로 앱으로 돌아올 때마다 다시 읽는다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(_provider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: AsyncStateView<RecordOverviewState>(
        value: ref.watch(_provider),
        errorTitle: '활동 기록을 불러오지 못했어요',
        onRetry: () => ref.invalidate(_provider),
        builder: _overview,
      ),
    );
  }

  Widget _overview(RecordOverviewState data) {
    final metrics = ImHereMetrics.of(context);
    final gap = SizedBox(height: metrics.resolve(ImHereSpace.sm));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.xs),
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 화면 전체 높이를 세 묶음이 똑같이 나눠 쓴다.
          Expanded(
            child: ActivitySection(
              title: '받은 알림',
              emptyTitle: '최근 받은 알림이 없어요',
              onShowAll: () => context.push('/record/notifications'),
              children: [
                for (final item in data.notifications)
                  ActivityCard(
                    title: item.title,
                    body: item.body,
                    meta: DateTimeFormatter.dateTime(item.createdAt),
                    onTap: item.id == null
                        ? null
                        : () =>
                              context.push('/record/notifications/${item.id}'),
                  ),
              ],
            ),
          ),
          gap,
          Expanded(
            child: ActivitySection(
              title: '친구 요청',
              emptyTitle: '대기 중인 친구 요청이 없어요',
              onShowAll: () => context.push('/friend/requests'),
              children: [
                for (final item in data.requests)
                  ActivityCard(
                    title: item.requester.nickname,
                    body: item.message,
                    meta: DateTimeFormatter.dateTimeFromIso(item.createdAt),
                    onTap: () => context.push('/friend/requests'),
                  ),
              ],
            ),
          ),
          gap,
          Expanded(
            child: ActivitySection(
              title: '전송 기록',
              emptyTitle: '자동 전송 기록이 없어요',
              onShowAll: () => context.push('/record/send-history'),
              children: [
                for (final item in data.records)
                  ActivityCard(
                    title: item.geofenceName,
                    body: item.message,
                    meta: DateTimeFormatter.dateTime(item.createdAt),
                    badge: RecordStatusBadge(status: item.status),
                    onTap: item.id == null
                        ? null
                        : () => context.push('/record/send-history/${item.id}'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
