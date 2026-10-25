import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_finder_view_model.g.dart';

const friendRequestMessageMaxLength = 200;
const defaultFriendRequestMessage = 'ImHere에서 친구가 되어 주세요';

class FriendFinderState {
  final List<FriendCandidate> results;
  final FriendCandidate? selected;
  final bool busy;
  final String status;

  const FriendFinderState({
    this.results = const [],
    this.selected,
    this.busy = false,
    this.status = '',
  });

  FriendFinderState copyWith({
    List<FriendCandidate>? results,
    FriendCandidate? selected,
    bool clearSelected = false,
    bool? busy,
    String? status,
  }) => FriendFinderState(
    results: results ?? this.results,
    selected: clearSelected ? null : selected ?? this.selected,
    busy: busy ?? this.busy,
    status: status ?? this.status,
  );
}

@riverpod
class FriendFinderViewModel extends _$FriendFinderViewModel {
  late FriendService _friends;

  @override
  FriendFinderState build(FriendService friendService) {
    _friends = friendService;
    return const FriendFinderState();
  }

  Future<void> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty || state.busy) return;
    state = const FriendFinderState(busy: true);
    try {
      final results = await _friends.search(trimmed);
      if (!ref.mounted) return;
      state = FriendFinderState(
        results: results,
        status: results.isEmpty ? '검색 결과가 없어요' : '',
      );
    } catch (error, stack) {
      AppLogger.error('User search failed', error, stack);
      if (ref.mounted) {
        state = const FriendFinderState(status: '사용자를 검색하지 못했어요');
      }
    }
  }

  void select(FriendCandidate candidate) {
    if (!candidate.relation.canRequest) return;
    state = state.copyWith(selected: candidate, status: '');
  }

  void clearSelection() =>
      state = state.copyWith(clearSelected: true, status: '');

  Future<void> sendRequest(String message) async {
    final target = state.selected;
    if (target == null || state.busy) return;
    state = state.copyWith(busy: true, status: '');
    try {
      await _friends.sendRequest(target.user.id, message.trim());
      await _logRequestSent();
      if (!ref.mounted) return;
      state = FriendFinderState(
        results: state.results
            .where((item) => item.user.id != target.user.id)
            .toList(),
        status: '${target.user.nickname}님에게 친구 요청을 보냈어요',
      );
    } catch (error, stack) {
      AppLogger.error('Friend request failed', error, stack);
      if (ref.mounted) {
        state = state.copyWith(busy: false, status: '친구 요청을 보내지 못했어요');
      }
    }
  }

  Future<void> _logRequestSent() async {
    try {
      await ref
          .read(authAnalyticsReporterProvider)
          .logEvent(
            'friend_request_sent',
            parameters: const {'source': 'search'},
          );
    } catch (error, stack) {
      AppLogger.error('Friend request analytics failed', error, stack);
    }
  }
}
