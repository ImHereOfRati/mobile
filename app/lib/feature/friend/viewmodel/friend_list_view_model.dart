import 'package:iamhere/core/paging/paged_items.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_list_view_model.g.dart';

class FriendListState {
  final PagedItems<FriendshipDto> friendships;
  final List<ContactEntity> contacts;

  const FriendListState({required this.friendships, required this.contacts});

  FriendListState copyWith({
    PagedItems<FriendshipDto>? friendships,
    List<ContactEntity>? contacts,
  }) => FriendListState(
    friendships: friendships ?? this.friendships,
    contacts: contacts ?? this.contacts,
  );
}

@riverpod
class FriendListViewModel extends _$FriendListViewModel {
  late FriendService _friends;
  late DeviceContactService _contacts;

  @override
  Future<FriendListState> build(
    FriendService friendService,
    DeviceContactService contactService,
  ) async {
    _friends = friendService;
    _contacts = contactService;
    final results = await Future.wait([
      friendService.loadFriendships(0),
      contactService.load(),
    ]);
    return FriendListState(
      friendships: results[0] as PagedItems<FriendshipDto>,
      contacts: results[1] as List<ContactEntity>,
    );
  }

  /// 기기 연락처 선택기를 바로 띄워 고른 연락처를 친구 목록에 더하고, 사용자에게
  /// 보여 줄 결과 문구를 돌려준다.
  Future<String> addContactFromDevice() async {
    try {
      final contact = await _contacts.pick();
      if (contact == null) return '연락처를 추가하지 않았어요';
      await reloadContacts();
      await _log('device_contact_added', const {'source': 'device_picker'});
      return '${contact.name} 연락처를 추가했어요';
    } catch (error, stack) {
      AppLogger.error('Contact import failed', error, stack);
      return '연락처를 가져오지 못했어요. 권한을 확인해 주세요';
    }
  }

  /// 로딩 화면으로 돌아가지 않고 연락처만 다시 읽는다.
  Future<void> reloadContacts() async {
    final current = state.value;
    if (current == null) return;
    try {
      final contacts = await _contacts.load();
      if (ref.mounted) state = AsyncData(current.copyWith(contacts: contacts));
    } catch (error, stack) {
      AppLogger.error('Contact reload failed', error, stack);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        !current.friendships.hasNext ||
        current.friendships.loadingMore) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        friendships: current.friendships.copyWith(loadingMore: true),
      ),
    );
    final nextPage = current.friendships.page + 1;
    try {
      final next = await _friends.loadFriendships(nextPage);
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ?? current).copyWith(
          friendships: current.friendships.append(next, nextPage),
        ),
      );
    } catch (error, stack) {
      AppLogger.error('Friend page load failed', error, stack);
      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(
            friendships: current.friendships.copyWith(loadingMore: false),
          ),
        );
      }
    }
  }

  /// 목록은 페이지를 넘기며 오래 살아 있어서, 다른 기기에서 별명이 바뀌면 화면의
  /// 값이 낡는다. 시트를 열 때 그 한 건만 서버에서 다시 읽고, 실패하면 목록의 값을
  /// 쓴다.
  Future<FriendshipDto> freshFriendship(FriendshipDto fallback) async {
    try {
      return await _friends.friendship(fallback.id);
    } catch (_) {
      return fallback;
    }
  }

  /// 성공하면 null, 실패하면 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> notifyArrival(FriendshipDto friendship) => _run(() async {
    await _friends.notifyArrival(friendship.friend.id);
    await _log('friend_arrival_notification_sent');
  }, '도착 알림을 보내지 못했어요');

  Future<String?> rename(FriendshipDto friendship, String alias) async {
    final trimmed = alias.trim();
    if (trimmed.isEmpty) return '별명을 입력해 주세요';
    return _run(() async {
      final updated = await _friends.updateAlias(friendship.id, trimmed);
      _update(
        (current) => current.copyWith(
          friendships: current.friendships.replaceWhere(
            (item) => item.id == updated.id,
            updated,
          ),
        ),
      );
    }, '친구 정보를 변경하지 못했어요');
  }

  Future<String?> deleteFriend(FriendshipDto friendship) => _run(() async {
    await _friends.deleteFriend(friendship.id);
    _removeFriendship(friendship);
  }, '친구를 삭제하지 못했어요');

  Future<String?> block(FriendshipDto friendship) => _run(() async {
    await _friends.block(friendship.friend.id);
    _removeFriendship(friendship);
  }, '친구를 차단하지 못했어요');

  Future<String?> renameContact(ContactEntity contact, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '닉네임을 입력해 주세요';
    return _run(() async {
      final updated = await _contacts.rename(contact.id!, trimmed);
      _update(
        (current) => current.copyWith(
          contacts: [
            for (final item in current.contacts)
              item.id == updated.id ? updated : item,
          ],
        ),
      );
    }, '닉네임을 저장하지 못했어요');
  }

  Future<String?> hideContact(ContactEntity contact) => _run(() async {
    await _contacts.hide(contact.id!);
    _update(
      (current) => current.copyWith(
        contacts: current.contacts
            .where((item) => item.id != contact.id)
            .toList(),
      ),
    );
  }, '기기 연락처를 삭제하지 못했어요');

  void _removeFriendship(FriendshipDto friendship) => _update(
    (current) => current.copyWith(
      friendships: current.friendships.removeWhere(
        (item) => item.id == friendship.id,
      ),
    ),
  );

  void _update(FriendListState Function(FriendListState current) change) {
    final current = state.value;
    if (current == null || !ref.mounted) return;
    state = AsyncData(change(current));
  }

  Future<String?> _run(
    Future<void> Function() action,
    String failureMessage,
  ) async {
    try {
      await action();
      return null;
    } catch (error, stack) {
      AppLogger.error(failureMessage, error, stack);
      return failureMessage;
    }
  }

  Future<void> _log(
    String name, [
    Map<String, Object> parameters = const {},
  ]) async {
    try {
      await ref
          .read(authAnalyticsReporterProvider)
          .logEvent(name, parameters: parameters);
    } catch (error, stack) {
      AppLogger.error('Friend analytics failed', error, stack);
    }
  }
}
