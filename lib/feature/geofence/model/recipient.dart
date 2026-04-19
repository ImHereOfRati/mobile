import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';

/// 지오펜스 알림 수신자 (로컬 연락처 / 서버 친구 통합 표현)
sealed class Recipient {
  const Recipient();

  String get selectionKey;
  String get displayName;
  String get displaySubtitle;
}

class LocalRecipient extends Recipient {
  final Contact contact;

  const LocalRecipient(this.contact);

  int? get id => contact.id;

  @override
  String get selectionKey => 'local:${contact.id}';

  @override
  String get displayName => contact.name;

  @override
  String get displaySubtitle => contact.number;
}

class ServerRecipient extends Recipient {
  final String friendRelationshipId;
  final String friendEmail;
  final String friendAlias;

  const ServerRecipient({
    required this.friendRelationshipId,
    required this.friendEmail,
    required this.friendAlias,
  });

  factory ServerRecipient.fromDto(FriendRelationshipResponseDto dto) =>
      ServerRecipient(
        friendRelationshipId: dto.friendRelationshipId,
        friendEmail: dto.friendEmail,
        friendAlias: dto.friendAlias,
      );

  @override
  String get selectionKey => 'server:$friendRelationshipId';

  @override
  String get displayName =>
      friendAlias.isNotEmpty ? friendAlias : friendEmail;

  @override
  String get displaySubtitle => friendEmail;
}
