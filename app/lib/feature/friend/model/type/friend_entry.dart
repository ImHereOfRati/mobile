import 'package:iamhere/feature/friend/model/dto/friendship_dto.dart';
import 'package:iamhere/feature/friend/model/repository/contact_entity.dart';

/// 친구 목록의 한 줄. ImHere 친구와 기기에서 고른 연락처를 한 목록에서 다룬다.
sealed class FriendEntry {
  const FriendEntry();

  String get key;
  String get displayName;
  String get description;
}

class ServerFriendEntry extends FriendEntry {
  final FriendshipDto friendship;

  const ServerFriendEntry(this.friendship);

  @override
  String get key => friendship.id;

  @override
  String get displayName => friendship.displayName;

  @override
  String get description => friendship.friend.email;
}

class DeviceFriendEntry extends FriendEntry {
  final ContactEntity contact;

  const DeviceFriendEntry(this.contact);

  @override
  String get key => 'device:${contact.id}';

  @override
  String get displayName => contact.name;

  @override
  String get description => contact.number;
}
