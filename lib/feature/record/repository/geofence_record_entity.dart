class GeofenceRecordEntity {
  final int? id;
  final int geofenceId; // 지오펜스 ID
  final String geofenceName; // 지오펜스 이름
  final String message; // 전송된 메시지
  final String recipients; // 수신자 목록 (JSON 형태, 예: "[\"홍길동\", \"김철수\"]")
  final DateTime createdAt; // 기록 생성 시간
  final SendMachine sendMachine; // 전송한 기기

  GeofenceRecordEntity({
    this.id,
    required this.geofenceId,
    required this.geofenceName,
    required this.message,
    required this.recipients,
    required this.createdAt,
    required this.sendMachine,
  });

  GeofenceRecordEntity copyWith({
    int? id,
    int? geofenceId,
    String? geofenceName,
    String? message,
    String? recipients,
    DateTime? createdAt,
    SendMachine? sendMachine,
  }) {
    return GeofenceRecordEntity(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      geofenceName: geofenceName ?? this.geofenceName,
      message: message ?? this.message,
      recipients: recipients ?? this.recipients,
      createdAt: createdAt ?? this.createdAt,
      sendMachine: sendMachine ?? this.sendMachine,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'geofence_id': geofenceId,
      'geofence_name': geofenceName,
      'message': message,
      'recipients': recipients,
      'created_at': createdAt.toIso8601String(),
      'send_machine': sendMachine.name,
    };
  }

  factory GeofenceRecordEntity.fromMap(Map<String, dynamic> map) {
    return GeofenceRecordEntity(
      id: map['id'] as int?,
      geofenceId: map['geofence_id'] as int,
      geofenceName: map['geofence_name'] as String,
      message: map['message'] as String,
      recipients: map['recipients'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      sendMachine: SendMachine.values.firstWhere(
        (e) => e.name == map['send_machine'],
        orElse: () => SendMachine.mobile,
      ),
    );
  }
}

enum SendMachine {
  mobile('이 기기에서'),
  server('서버에서');

  final String description;

  const SendMachine(this.description);
}
