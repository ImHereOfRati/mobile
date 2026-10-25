enum RecipientSource {
  server('ImHere 친구'),
  device('기기 연락처');

  final String label;

  const RecipientSource(this.label);
}

/// 알림을 받을 수 있는 한 사람. ImHere 친구이거나 기기 연락처다.
class RecipientOption {
  final String key;
  final String label;
  final String description;
  final RecipientSource source;

  /// 서버 친구일 때만 채워진다. 지오펜스에 저장되는 친구 정보다.
  final ServerRecipientInfo? server;

  const RecipientOption({
    required this.key,
    required this.label,
    required this.description,
    required this.source,
    this.server,
  });
}

class ServerRecipientInfo {
  final String friendRelationshipId;
  final String friendUserId;
  final String friendEmail;
  final String friendAlias;

  const ServerRecipientInfo({
    required this.friendRelationshipId,
    required this.friendUserId,
    required this.friendEmail,
    required this.friendAlias,
  });
}
