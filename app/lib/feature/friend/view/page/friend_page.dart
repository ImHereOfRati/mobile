import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/core/view/infinite_scroll.dart';
import 'package:iamhere/core/view/paged_footer.dart';
import 'package:iamhere/core/view/text_edit_sheet.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_grouping.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/model/type/friend_entry.dart';
import 'package:iamhere/feature/friend/view/widget/friend_actions_sheet.dart';
import 'package:iamhere/feature/friend/view/widget/friend_finder_sheet.dart';
import 'package:iamhere/feature/friend/viewmodel/friend_list_view_model.dart';

const _aliasMaxLength = 30;

class FriendPage extends ConsumerStatefulWidget {
  final FriendService friendService;
  final DeviceContactService contactService;

  /// `/friend/add`로 들어오면 친구 찾기 시트를 바로 연다.
  final bool finderInitiallyOpen;

  const FriendPage({
    super.key,
    required this.friendService,
    required this.contactService,
    this.finderInitiallyOpen = false,
  });

  @override
  ConsumerState<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends ConsumerState<FriendPage> {
  FriendListViewModelProvider get _provider =>
      friendListViewModelProvider(widget.friendService, widget.contactService);

  @override
  void initState() {
    super.initState();
    if (widget.finderInitiallyOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFinder();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: AsyncStateView<FriendListState>(
        value: ref.watch(_provider),
        errorTitle: '친구 목록을 불러오지 못했어요',
        onRetry: () => ref.invalidate(_provider),
        builder: _list,
      ),
    );
  }

  Widget _list(FriendListState data) {
    final metrics = ImHereMetrics.of(context);
    final groups = FriendGrouping.group(
      FriendGrouping.merge(data.friendships.items, data.contacts),
    );
    final total = groups.values.fold<int>(
      0,
      (sum, entries) => sum + entries.length,
    );

    return InfiniteScroll(
      hasNext: data.friendships.hasNext,
      onLoadMore: () => ref.read(_provider.notifier).loadMore(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.md),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xl),
        ),
        children: [
          // 친구를 더하는 두 방법은 한 번의 탭으로 바로 시작한다.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ActionTile(
                    glyph: ImHereGlyph.add,
                    title: '친구 찾기',
                    subtitle: '닉네임·이메일로 요청',
                    onTap: _openFinder,
                  ),
                ),
                SizedBox(width: metrics.resolve(ImHereSpace.sm)),
                Expanded(
                  child: _ActionTile(
                    glyph: ImHereGlyph.person,
                    title: '연락처 추가',
                    subtitle: '기기에서 바로 선택',
                    onTap: _addContact,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          ImHereListRow(
            title: '받은 요청',
            leading: const ImHereIcon(glyph: ImHereGlyph.bell, size: 22),
            onTap: () => context.push('/friend/requests'),
          ),
          const ImHereBorder(tone: ImHereDividerTone.subtle),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          if (groups.isEmpty)
            ImHereStatePanel(
              glyph: ImHereGlyph.friends,
              title: '아직 등록된 친구가 없어요',
              description: '위에서 친구를 찾거나 연락처를 추가해 보세요',
            )
          else ...[
            ImHereListHeader(
              title: '친구 $total명',
              actionLabel: '관리',
              onAction: () => context.push('/friend/restrictions'),
            ),
            for (final group in groups.entries) ...[
              ImHereListHeader(title: group.key),
              for (final entry in group.value) _row(entry),
              SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            ],
          ],
          PagedFooter(loading: data.friendships.loadingMore),
        ],
      ),
    );
  }

  Widget _row(FriendEntry entry) {
    return ImHereListRow(
      title: entry.displayName,
      description: entry.description.isEmpty ? '전화번호 없음' : entry.description,
      leading: ImHereAvatar(name: entry.displayName),
      // 기기 연락처만 표시해 ImHere 친구와 구분한다.
      trailing: entry is DeviceFriendEntry
          ? const ImHereBadge(
              label: '연락처',
              tone: ImHereBadgeTone.neutral,
              size: ImHereBadgeSize.medium,
            )
          : null,
      onTap: () => switch (entry) {
        ServerFriendEntry(:final friendship) => _openFriend(friendship),
        DeviceFriendEntry(:final contact) => _openContact(contact),
      },
    );
  }

  Future<void> _openFinder() {
    return showFriendFinderSheet(context, friendService: widget.friendService);
  }

  /// 시트를 거치지 않고 기기 연락처 선택기를 바로 연다.
  Future<void> _addContact() async {
    final message = await ref.read(_provider.notifier).addContactFromDevice();
    _toast(message);
  }

  Future<void> _openFriend(FriendshipDto friendship) async {
    final viewModel = ref.read(_provider.notifier);
    final action = await showFriendActionsSheet(
      context,
      friendship: friendship,
      fresh: viewModel.freshFriendship(friendship),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case FriendAction.notifyArrival:
        final failure = await viewModel.notifyArrival(friendship);
        _toast(failure ?? '도착 알림을 보냈어요');
      case FriendAction.rename:
        final saved = await showTextEditSheet(
          context,
          title: '별명 수정',
          label: '별명',
          initial: friendship.displayName,
          maxLength: _aliasMaxLength,
          onSave: (value) => viewModel.rename(friendship, value),
        );
        if (saved == true) _toast('별명을 바꿨어요');
      case FriendAction.delete:
        if (await _confirm(
          title: '${friendship.displayName}님을 친구에서 삭제할까요?',
          confirmLabel: '삭제',
        )) {
          final failure = await viewModel.deleteFriend(friendship);
          _toast(failure ?? '친구를 삭제했어요');
        }
      case FriendAction.block:
        if (await _confirm(
          title: '${friendship.displayName}님을 차단할까요?',
          description: '친구 관리에서 언제든 해제할 수 있어요',
          confirmLabel: '차단',
        )) {
          final failure = await viewModel.block(friendship);
          _toast(failure ?? '친구를 차단했어요');
        }
    }
  }

  Future<void> _openContact(ContactEntity contact) async {
    final action = await showContactActionsSheet(context, contact: contact);
    if (action == null || !mounted) return;
    switch (action) {
      case ContactAction.rename:
        context.push('/friend/device-contact/${contact.id}/edit');
      case ContactAction.delete:
        if (await _confirm(
          title: '${contact.name} 연락처를 삭제할까요?',
          confirmLabel: '삭제',
        )) {
          final failure = await ref
              .read(_provider.notifier)
              .hideContact(contact);
          _toast(failure ?? '연락처를 삭제했어요');
        }
    }
  }

  Future<bool> _confirm({
    required String title,
    String? description,
    required String confirmLabel,
  }) async {
    final confirmed = await showImHereDialog(
      context,
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      destructive: true,
    );
    return confirmed == true && mounted;
  }

  void _toast(String message) {
    if (mounted) showImHereSnackbar(context, message);
  }
}

/// 친구를 더하는 방법 하나. 눌러서 바로 시작한다.
class _ActionTile extends StatelessWidget {
  final ImHereGlyph glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: ImHereSurface(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: metrics.resolve(36),
              height: metrics.resolve(36),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.actionSubtle,
                shape: BoxShape.circle,
              ),
              child: ImHereIcon(glyph: glyph, size: 20, color: colors.action),
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            Text(title, style: textTheme.titleSmall),
            SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
