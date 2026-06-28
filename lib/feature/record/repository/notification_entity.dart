class NotificationEntity {
  final int? id;
  final String title;
  final String body;
  final String senderNickname;
  final String senderEmail;
  final String path;
  final DateTime createdAt;

  NotificationEntity({
    this.id,
    required this.title,
    required this.body,
    required this.senderNickname,
    required this.senderEmail,
    this.path = '',
    required this.createdAt,
  });

  NotificationEntity copyWith({
    int? id,
    String? title,
    String? body,
    String? senderNickname,
    String? senderEmail,
    String? path,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      senderNickname: senderNickname ?? this.senderNickname,
      senderEmail: senderEmail ?? this.senderEmail,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sender_nickname': senderNickname,
      'sender_email': senderEmail,
      'path': path,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      senderNickname: map['sender_nickname'] as String,
      senderEmail: map['sender_email'] as String,
      path: map['path'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
