import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/core/view/infinite_scroll.dart';
import 'package:iamhere/core/view/paged_footer.dart';
import 'package:iamhere/feature/friend/model/dto/friend_restriction_dto.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/viewmodel/friend_restrictions_view_model.dart';

class FriendRestrictionsPage extends ConsumerWidget {
  final FriendService friendService;

  const FriendRestrictionsPage({super.key, required this.friendService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = friendRestrictionsViewModelProvider(friendService);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: AsyncStateView<PagedItems<FriendRestrictionDto>>(
        value: ref.watch(provider),
        errorTitle: '차단·거절 목록을 불러오지 못했어요',
        onRetry: () => ref.invalidate(provider),
        builder: (page) {
          if (page.items.isEmpty) {
            return const ImHereStatePanel(
              glyph: ImHereGlyph.person,
              title: '제한한 사용자가 없어요',
              size: ImHereStateSize.large,
            );
          }
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
                  '다시 연결할 수 있도록 기존 제한을 해제할 수 있어요',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.md)),
                for (final item in page.items) ...[
                  _RestrictionCard(
                    item: item,
                    onUnblock: () => _unblock(context, ref, provider, item),
                  ),
                  SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                ],
                PagedFooter(loading: page.loadingMore),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    FriendRestrictionsViewModelProvider provider,
    FriendRestrictionDto item,
  ) async {
    final confirmed = await showImHereDialog(
      context,
      title: '${item.restricted.nickname}님의 제한을 해제할까요?',
      confirmLabel: '제한 해제',
    );
    if (confirmed != true || !context.mounted) return;
    final failure = await ref.read(provider.notifier).unblock(item);
    if (context.mounted) {
      showImHereSnackbar(context, failure ?? '제한을 해제했어요');
    }
  }
}

class _RestrictionCard extends StatelessWidget {
  final FriendRestrictionDto item;
  final VoidCallback onUnblock;

  const _RestrictionCard({required this.item, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ImHereSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImHereAvatar(name: item.restricted.nickname),
              SizedBox(width: metrics.resolve(ImHereSpace.sm)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.restricted.nickname, style: textTheme.titleSmall),
                    Text(
                      item.restricted.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ImHereBadge(
                label: item.isBlock ? '차단' : '거절',
                tone: ImHereBadgeTone.neutral,
                size: ImHereBadgeSize.medium,
              ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          ImHereButton(
            label: '제한 해제',
            tone: ImHereButtonTone.weak,
            size: ImHereButtonSize.sm,
            onPressed: onUnblock,
          ),
        ],
      ),
    );
  }
}
