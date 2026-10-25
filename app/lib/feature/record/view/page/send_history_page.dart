import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/date_time_formatter.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/core/view/infinite_scroll.dart';
import 'package:iamhere/core/view/paged_footer.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:iamhere/feature/record/view/widget/activity_card.dart';
import 'package:iamhere/feature/record/viewmodel/send_history_view_model.dart';

/// 네이티브 자동 전송 파이프라인이 남긴 결과 목록.
class SendHistoryPage extends ConsumerStatefulWidget {
  final ActivityLogService activityLog;

  const SendHistoryPage({super.key, required this.activityLog});

  @override
  ConsumerState<SendHistoryPage> createState() => _SendHistoryPageState();
}

class _SendHistoryPageState extends ConsumerState<SendHistoryPage>
    with WidgetsBindingObserver {
  SendHistoryViewModelProvider get _provider =>
      sendHistoryViewModelProvider(widget.activityLog);

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

  // 전송은 백그라운드에서 일어나므로 앱으로 돌아올 때마다 다시 읽는다.
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
      body: AsyncStateView<PagedItems<GeofenceRecordEntity>>(
        value: ref.watch(_provider),
        errorTitle: '전송 기록을 불러오지 못했어요',
        onRetry: () => ref.invalidate(_provider),
        builder: _list,
      ),
    );
  }

  Widget _list(PagedItems<GeofenceRecordEntity> page) {
    if (page.items.isEmpty) {
      return const ImHereStatePanel(
        glyph: ImHereGlyph.history,
        title: '전송 기록이 없어요',
        description: '자동 전송이 일어나면 결과가 여기에 쌓여요',
        size: ImHereStateSize.large,
      );
    }
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return InfiniteScroll(
      hasNext: page.hasNext,
      onLoadMore: () => ref.read(_provider.notifier).loadMore(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.navToTitle),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xl),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '자동 전송 파이프라인이 남긴 결과예요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              ImHereButton(
                label: '전체 삭제',
                tone: ImHereButtonTone.quiet,
                size: ImHereButtonSize.sm,
                onPressed: _confirmDeleteAll,
              ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          for (final item in page.items) ...[
            ActivityCard(
              title: item.geofenceName,
              body: item.message,
              meta: DateTimeFormatter.dateTime(item.createdAt),
              badge: RecordStatusBadge(status: item.status),
              onTap: item.id == null
                  ? null
                  : () => context.push('/record/send-history/${item.id}'),
              actions: [
                ImHereButton(
                  label: '기록 삭제',
                  tone: ImHereButtonTone.quiet,
                  size: ImHereButtonSize.sm,
                  onPressed: () => _confirmDelete(item),
                ),
              ],
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          ],
          PagedFooter(loading: page.loadingMore),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(GeofenceRecordEntity item) async {
    final confirmed = await showImHereDialog(
      context,
      title: '${item.geofenceName} 전송 기록을 삭제할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref.read(_provider.notifier).delete(item);
    _toast(failure ?? '전송 기록을 삭제했어요');
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showImHereDialog(
      context,
      title: '모든 전송 기록을 삭제할까요?',
      description: '삭제한 기록은 되돌릴 수 없어요',
      confirmLabel: '전체 삭제',
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref.read(_provider.notifier).deleteAll();
    _toast(failure ?? '모든 전송 기록을 삭제했어요');
  }

  void _toast(String message) {
    if (mounted) showImHereSnackbar(context, message);
  }
}
