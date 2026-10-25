/// 서버 알림함의 한 건. 기기에 쌓이는 알림([NotificationEntity])과는 다른
/// 저장소다. 서버 쪽은 발송 이력 전체를 들고 있어 기기를 바꿔도 남아 있고, 읽음
/// 상태를 계정 단위로 공유한다.
class ServerNotificationDto {
  final int id;
  final String title;
  final String body;
  final String senderAlias;
  final String type;
  final String status;
  final bool isRead;
  final String createdAt;

  const ServerNotificationDto({
    required this.id,
    required this.title,
    required this.body,
    required this.senderAlias,
    required this.type,
    required this.status,
    required this.isRead,
    required this.createdAt,
  });

  ServerNotificationDto asRead() => ServerNotificationDto(
    id: id,
    title: title,
    body: body,
    senderAlias: senderAlias,
    type: type,
    status: status,
    isRead: true,
    createdAt: createdAt,
  );

  /// 발송 상태를 사용자에게 보여 줄 말로 바꾼다.
  String get statusLabel => switch (status) {
    'QUEUED' => '발송 대기',
    'SENT' => '발송됨',
    'DELIVERED' => '전달됨',
    'FAILED' || 'DEAD' => '발송 실패',
    _ => status,
  };

  factory ServerNotificationDto.fromJson(Map<String, dynamic> json) =>
      ServerNotificationDto(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        senderAlias: json['senderAlias'] as String? ?? '',
        type: json['type'] as String? ?? '',
        status: json['status'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );
}
