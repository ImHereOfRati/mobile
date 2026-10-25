import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/geofence/model/type/recipient_option.dart';
import 'package:injectable/injectable.dart';

/// 장소 알림을 받을 수 있는 사람 목록. ImHere 친구와 기기 연락처를 한 목록으로 준다.
@injectable
class GeofenceRecipientService {
  /// 친구가 아주 많아도 화면이 끝없이 읽지 않도록 가져오는 쪽 수를 제한한다.
  static const _maxFriendPages = 10;

  final FriendService _friends;
  final DeviceContactService _contacts;

  GeofenceRecipientService(this._friends, this._contacts);

  /// 친구와 연락처는 서로 독립이다. 한쪽이 실패해도 다른 쪽은 보여 준다.
  Future<List<RecipientOption>> load() async {
    final results = await Future.wait([_serverOptions(), _deviceOptions()]);
    return [...results[0], ...results[1]];
  }

  Future<List<RecipientOption>> _serverOptions() async {
    try {
      final options = <RecipientOption>[];
      for (var page = 0; page < _maxFriendPages; page++) {
        final result = await _friends.loadFriendships(page);
        for (final friendship in result.items) {
          options.add(
            RecipientOption(
              key: friendship.id,
              label: friendship.displayName,
              description: friendship.friend.email,
              source: RecipientSource.server,
              server: ServerRecipientInfo(
                friendRelationshipId: friendship.id,
                friendUserId: friendship.friend.id,
                friendEmail: friendship.friend.email,
                friendAlias: friendship.displayName,
              ),
            ),
          );
        }
        if (!result.hasNext) break;
      }
      return options;
    } catch (error, stack) {
      AppLogger.error('Friend recipients load failed', error, stack);
      return const [];
    }
  }

  Future<List<RecipientOption>> _deviceOptions() async {
    try {
      final knownPhones = <String>{};
      final options = <RecipientOption>[];
      for (final contact in await _contacts.load()) {
        final digits = contact.number.replaceAll(RegExp(r'\D'), '');
        if (digits.isEmpty || !knownPhones.add(digits)) continue;
        options.add(
          RecipientOption(
            key: contact.id.toString(),
            label: contact.name,
            description: contact.number,
            source: RecipientSource.device,
          ),
        );
      }
      return options;
    } catch (error, stack) {
      AppLogger.error('Device recipients load failed', error, stack);
      return const [];
    }
  }
}
