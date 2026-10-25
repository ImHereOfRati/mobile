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
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final groups = FriendGrouping.group(
      FriendGrouping.merge(data.friendships.items, data.contacts),
    );

    return InfiniteScroll(
      hasNext: data.friendships.hasNext,
      onLoadMore: () => ref.read(_provider.notifier).loadMore(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.navToTitle),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xl),
        ),
        children: [
          Text('친구', style: textTheme.titleLarge),
          SizedBox(height: metrics.resolve(6)),
          Text(
            'ImHere 친구와 기기 연락처를 한곳에서 확인하세요',
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          Wrap(
            spacing: metrics.resolve(ImHereSpace.xs),
            runSpacing: metrics.resolve(ImHereSpace.xs),
            children: [
              ImHereButton(
                label: '친구 추가',
                size: ImHereButtonSize.sm,
                onPressed: _openFinder,
              ),
              ImHereButton(
                label: '받은 요청',
                tone: ImHereButtonTone.weak,
                size: ImHereButtonSize.sm,
                onPressed: () => context.push('/friend/requests'),
              ),
              ImHereButton(
                label: '친구 관리',
                tone: ImHereButtonTone.weak,
                size: ImHereButtonSize.sm,
                onPressed: () => context.push('/friend/restrictions'),
              ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.lg)),
          if (groups.isEmpty)
            ImHereStatePanel(
              glyph: ImHereGlyph.friends,
              title: '아직 등록된 친구가 없어요',
              description: '닉네임이나 이메일로 친구를 찾아 요청을 보내 보세요',
              actionLabel: '친구 추가',
              onAction: _openFinder,
            )
          else
            for (final group in groups.entries) ...[
              ImHereListHeader(title: group.key),
              for (final entry in group.value) _row(entry),
              SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            ],
          PagedFooter(loading: data.friendships.loadingMore),
        ],
      ),
    );
  }

  Widget _row(FriendEntry entry) {
    final kind = switch (entry) {
      ServerFriendEntry() => 'ImHere 친구',
      DeviceFriendEntry() => '기기 연락처',
    };
    final description = entry.description.isEmpty
        ? '전화번호 없음'
        : entry.description;
    return ImHereListRow(
      title: entry.displayName,
      description: '$description · $kind',
      leading: ImHereAvatar(name: entry.displayName),
      onTap: () => switch (entry) {
        ServerFriendEntry(:final friendship) => _openFriend(friendship),
        DeviceFriendEntry(:final contact) => _openContact(contact),
      },
    );
  }

  Future<void> _openFinder() async {
    await showFriendFinderSheet(
      context,
      friendService: widget.friendService,
      contactService: widget.contactService,
    );
    if (mounted) await ref.read(_provider.notifier).reloadContacts();
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
