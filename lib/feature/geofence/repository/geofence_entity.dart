class GeofenceEntity {
  final int? id;
  final String name;
  final String address; // 장소의 완전한 주소
  final double lat;
  final double lng;
  final double radius; // 반경 (미터)
  final String message; // 알림 메시지
  final String contactIds; // 연락처 ID 리스트 (JSON 형태로 저장, 예: "[1,2,3]")
  final bool isActive; // 활성화 상태
  final int serverRecipientCount; // IMHERE 서버 친구 숫자

  GeofenceEntity({
    this.id,
    required this.name,
    this.address = '',
    required this.lat,
    required this.lng,
    required this.radius,
    required this.message,
    required this.contactIds,
    this.isActive = false,
    this.serverRecipientCount = 0, // 기본값 0 보장
  });

  /// SMS 발송 시 사용할 location 문자열: "장소명 (주소)"
  String get fullLocation =>
      address.isNotEmpty ? '$name ($address)' : name;

  // isActive를 변경한 새 인스턴스 생성
  GeofenceEntity copyWith({
    int? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    double? radius,
    String? message,
    String? contactIds,
    bool? isActive,
    int? serverRecipientCount,
  }) {
    return GeofenceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      message: message ?? this.message,
      contactIds: contactIds ?? this.contactIds,
      isActive: isActive ?? this.isActive,
      serverRecipientCount: serverRecipientCount ?? this.serverRecipientCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'message': message,
      'contact_ids': contactIds,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory GeofenceEntity.fromMap(Map<String, dynamic> map) {
    return GeofenceEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String? ?? '',
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      radius: map['radius'] as double,
      message: map['message'] as String,
      contactIds: map['contact_ids'] as String? ?? '[]',
      isActive: (map['is_active'] as int? ?? 0) == 1,
      serverRecipientCount: map['server_recipient_count'] as int? ?? 0,
    );
  }
}
