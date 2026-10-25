import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/date_time_formatter.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/core/view/infinite_scroll.dart';
import 'package:iamhere/core/view/paged_footer.dart';
import 'package:iamhere/feature/friend/model/dto/friend_request_dto.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/model/type/friend_request_view_type.dart';
import 'package:iamhere/feature/friend/viewmodel/friend_requests_view_model.dart';

class FriendRequestsPage extends StatefulWidget {
  final FriendService friendService;

  const FriendRequestsPage({super.key, required this.friendService});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  var _type = FriendRequestViewType.received;

  @override
  Widget build(BuildContext context) {
    const types = FriendRequestViewType.values;
    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: Column(
        children: [
          ImHereTabBar(
            labels: [for (final type in types) type.label],
            index: types.indexOf(_type),
            onChanged: (index) => setState(() => _type = types[index]),
          ),
          Expanded(
            // 탭을 바꾸면 목록 상태를 새로 만든다.
            child: _RequestList(
              key: ValueKey(_type),
              friendService: widget.friendService,
              type: _type,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final FriendService friendService;
  final FriendRequestViewType type;

  const _RequestList({
    super.key,
    required this.friendService,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = friendRequestsViewModelProvider(friendService, type);
    final metrics = ImHereMetrics.of(context);
    return AsyncStateView<PagedItems<FriendRequestDto>>(
      value: ref.watch(provider),
      errorTitle: '친구 요청을 불러오지 못했어요',
      onRetry: () => ref.invalidate(provider),
      builder: (page) {
        if (page.items.isEmpty) {
          return ImHereStatePanel(
            glyph: ImHereGlyph.friends,
            title: type.emptyText,
            size: ImHereStateSize.large,
          );
        }
        return InfiniteScroll(
          hasNext: page.hasNext,
          onLoadMore: () => ref.read(provider.notifier).loadMore(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.md),
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.xl),
            ),
            children: [
              for (final request in page.items) ...[
                _RequestCard(
                  key: ValueKey(request.id),
                  request: request,
                  type: type,
                  viewModel: ref.read(provider.notifier),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.sm)),
              ],
              PagedFooter(loading: page.loadingMore),
            ],
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final FriendRequestDto request;
  final FriendRequestViewType type;
  final FriendRequestsViewModel viewModel;

  const _RequestCard({
    super.key,
    required this.request,
    required this.type,
    required this.viewModel,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  FriendRequestDto? _detail;

  bool get _sent => widget.type == FriendRequestViewType.sent;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final request = widget.request;
    final counterpart = _sent ? request.receiver : request.requester;
    final detail = _detail;

    return ImHereSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImHereAvatar(name: counterpart.nickname),
              SizedBox(width: metrics.resolve(ImHereSpace.sm)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(counterpart.nickname, style: textTheme.titleSmall),
                    Text(
                      counterpart.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.message.isNotEmpty) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            Text(request.message, style: textTheme.bodyMedium),
          ],
          if (detail != null) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            ImHereCallout(
              text: [
                '보낸 사람 ${detail.requester.nickname} · 받는 사람 ${detail.receiver.nickname}',
                '요청 ${DateTimeFormatter.dateTimeFromIso(detail.createdAt)}',
              ].join('\n'),
            ),
          ],
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Wrap(
            spacing: metrics.resolve(ImHereSpace.xs),
            runSpacing: metrics.resolve(ImHereSpace.xs),
            children: [
              if (!_sent) ...[
                ImHereButton(
                  label: '수락',
                  size: ImHereButtonSize.sm,
                  onPressed: () => _respond(accept: true),
                ),
                ImHereButton(
                  label: '거절',
                  tone: ImHereButtonTone.weak,
                  size: ImHereButtonSize.sm,
                  onPressed: () => _respond(accept: false),
                ),
              ],
              ImHereButton(
                label: detail == null ? '상세 보기' : '상세 닫기',
                tone: ImHereButtonTone.ghost,
                size: ImHereButtonSize.sm,
                onPressed: _toggleDetail,
              ),
              ImHereButton(
                label: _sent ? '요청 취소' : '요청 삭제',
                tone: ImHereButtonTone.quiet,
                size: ImHereButtonSize.sm,
                onPressed: _discard,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respond({required bool accept}) async {
    final message = await widget.viewModel.respond(
      widget.request,
      accept: accept,
    );
    _toast(message);
  }

  // 삭제와 취소는 거절과 달리 되돌릴 수 없어 확인을 받는다.
  Future<void> _discard() async {
    final label = _sent ? '취소' : '삭제';
    final counterpart = _sent
        ? widget.request.receiver
        : widget.request.requester;
    final confirmed = await showImHereDialog(
      context,
      title: '${counterpart.nickname}님과의 요청을 $label할까요?',
      confirmLabel: label,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    _toast(await widget.viewModel.discard(widget.request));
  }

  Future<void> _toggleDetail() async {
    if (_detail != null) {
      setState(() => _detail = null);
      return;
    }
    final detail = await widget.viewModel.detail(widget.request);
    if (!mounted) return;
    if (detail == null) {
      _toast('요청 상세를 불러오지 못했어요');
      return;
    }
    setState(() => _detail = detail);
  }

  void _toast(String message) {
    if (mounted) showImHereSnackbar(context, message);
  }
}
