import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/date_time_formatter.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/core/view/infinite_scroll.dart';
import 'package:iamhere/core/view/paged_footer.dart';
import 'package:iamhere/feature/record/model/dto/server_notification_dto.dart';
import 'package:iamhere/feature/record/model/service/server_notification_service.dart';
import 'package:iamhere/feature/record/view/widget/activity_card.dart';
import 'package:iamhere/feature/record/viewmodel/server_notifications_view_model.dart';

/// 받은 알림 전체 보기. 기기에 남은 알림이 아니라 계정에 쌓인 서버 알림함이다.
class ServerNotificationsPage extends ConsumerWidget {
  final ServerNotificationService service;

  const ServerNotificationsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = serverNotificationsViewModelProvider(service);
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: AsyncStateView<PagedItems<ServerNotificationDto>>(
        value: ref.watch(provider),
        errorTitle: '알림을 불러오지 못했어요',
        onRetry: () => ref.invalidate(provider),
        builder: (page) {
          if (page.items.isEmpty) {
            return const ImHereStatePanel(
              glyph: ImHereGlyph.bell,
              title: '계정에 쌓인 알림이 없어요',
              size: ImHereStateSize.large,
            );
          }
          final unread = page.items.where((item) => !item.isRead).length;
          return InfiniteScroll(
            hasNext: page.hasNext,
            onLoadMore: () => ref.read(provider.notifier).loadMore(),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                metrics.resolve(ImHereSpace.gutter),
                metrics.resolve(ImHereSpace.navToTitle),
                metrics.resolve(ImHereSpace.gutter),
                metrics.resolve(ImHereSpace.xl),
              ),
              children: [
                Text(
                  [
                    '기기에 남은 알림과 달리 계정에 쌓인 알림이에요.',
                    '기기를 바꿔도 그대로 남아요.',
                  ].join('\n'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                if (unread > 0) ...[
                  SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '읽지 않은 알림 $unread건',
                      style: textTheme.titleSmall,
                    ),
                  ),
                ],
                SizedBox(height: metrics.resolve(ImHereSpace.md)),
                for (final item in page.items) ...[
                  ActivityCard(
                    title: item.title,
                    body: item.body,
                    meta:
                        '${item.senderAlias} · '
                        '${DateTimeFormatter.dateTimeFromIso(item.createdAt)}'
                        ' · ${item.statusLabel}',
                    badge: item.isRead
                        ? null
                        : const ImHereBadge(
                            label: '안 읽음',
                            size: ImHereBadgeSize.medium,
                          ),
                    actions: [
                      if (!item.isRead)
                        ImHereButton(
                          label: '읽음으로 표시',
                          tone: ImHereButtonTone.weak,
                          size: ImHereButtonSize.sm,
                          onPressed: () => _markAsRead(context, ref, item),
                        ),
                    ],
                  ),
                  SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                ],
                PagedFooter(loading: page.loadingMore),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsRead(
    BuildContext context,
    WidgetRef ref,
    ServerNotificationDto item,
  ) async {
    final failure = await ref
        .read(serverNotificationsViewModelProvider(service).notifier)
        .markAsRead(item);
    if (failure != null && context.mounted) {
      showImHereSnackbar(context, failure);
    }
  }
}
