import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/viewmodel/friend_finder_view_model.dart';

/// 닉네임이나 이메일로 친구를 찾아 요청을 보내는 시트.
Future<void> showFriendFinderSheet(
  BuildContext context, {
  required FriendService friendService,
}) {
  return showImHereSheet<void>(
    context,
    title: '친구 찾기',
    builder: (_) => FriendFinderSheet(friendService: friendService),
  );
}

class FriendFinderSheet extends ConsumerStatefulWidget {
  final FriendService friendService;

  const FriendFinderSheet({super.key, required this.friendService});

  @override
  ConsumerState<FriendFinderSheet> createState() => _FriendFinderSheetState();
}

class _FriendFinderSheetState extends ConsumerState<FriendFinderSheet> {
  final _keyword = TextEditingController();
  final _message = TextEditingController(text: defaultFriendRequestMessage);

  FriendFinderViewModelProvider get _provider =>
      friendFinderViewModelProvider(widget.friendService);

  @override
  void dispose() {
    _keyword.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final viewModel = ref.read(_provider.notifier);
    final metrics = ImHereMetrics.of(context);
    final gap = SizedBox(height: metrics.resolve(ImHereSpace.sm));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.selected == null)
              ..._searchForm(state, viewModel, gap)
            else
              ..._requestForm(state, viewModel, gap),
            if (state.status.isNotEmpty) ...[
              gap,
              Semantics(
                liveRegion: true,
                child: Text(
                  state.status,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ImHereColors.of(context).textMuted,
                  ),
                ),
              ),
            ],
            if (state.selected == null && state.results.isNotEmpty) ...[
              gap,
              ImHereListHeader(title: '검색 결과'),
              for (final candidate in state.results)
                ImHereListRow(
                  title: candidate.user.nickname,
                  description: candidate.user.email,
                  leading: ImHereAvatar(name: candidate.user.nickname),
                  trailing: candidate.relation.canRequest
                      ? ImHereButton(
                          label: '선택',
                          tone: ImHereButtonTone.weak,
                          size: ImHereButtonSize.sm,
                          onPressed: () => viewModel.select(candidate),
                        )
                      : ImHereBadge(
                          label: candidate.relation.label,
                          tone: ImHereBadgeTone.neutral,
                          size: ImHereBadgeSize.medium,
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _searchForm(
    FriendFinderState state,
    FriendFinderViewModel viewModel,
    Widget gap,
  ) {
    return [
      ImHereTextField(
        label: '닉네임 또는 이메일',
        controller: _keyword,
        hint: '닉네임 또는 이메일',
        enabled: !state.busy,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => viewModel.search(_keyword.text),
      ),
      gap,
      ImHereButton(
        label: '검색',
        expand: true,
        loading: state.busy,
        onPressed: state.busy ? null : () => viewModel.search(_keyword.text),
      ),
    ];
  }

  List<Widget> _requestForm(
    FriendFinderState state,
    FriendFinderViewModel viewModel,
    Widget gap,
  ) {
    final user = state.selected!.user;
    return [
      ImHereListRow(
        title: user.nickname,
        description: user.email,
        leading: ImHereAvatar(name: user.nickname),
        trailing: ImHereButton(
          label: '다시 선택',
          tone: ImHereButtonTone.ghost,
          size: ImHereButtonSize.sm,
          onPressed: state.busy ? null : viewModel.clearSelection,
        ),
      ),
      gap,
      ImHereTextField(
        label: '요청 메시지',
        controller: _message,
        maxLength: friendRequestMessageMaxLength,
        maxLines: 3,
        enabled: !state.busy,
      ),
      gap,
      ImHereButton(
        label: '친구 요청 보내기',
        expand: true,
        loading: state.busy,
        onPressed: state.busy
            ? null
            : () => viewModel.sendRequest(_message.text),
      ),
    ];
  }
}
