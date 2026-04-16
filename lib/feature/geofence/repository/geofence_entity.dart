class GeofenceEntity {
  final int? id;
  final String name;
  final double lat;
  final double lng;
  final double radius; // 반경 (미터)
  final String message; // 알림 메시지
  final String contactIds; // 연락처 ID 리스트 (JSON 형태로 저장, 예: "[1,2,3]")
  final bool isActive; // 활성화 상태

  GeofenceEntity({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.message,
    required this.contactIds,
    this.isActive = false, // 기본값은 false
  });

  // isActive를 변경한 새 인스턴스 생성
  GeofenceEntity copyWith({
    int? id,
    String? name,
    double? lat,
    double? lng,
    double? radius,
    String? message,
    String? contactIds,
    bool? isActive,
  }) {
    return GeofenceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      message: message ?? this.message,
      contactIds: contactIds ?? this.contactIds,
      // isActive가 null이 아닐 때만 업데이트 (false도 포함)
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'message': message,
      'contact_ids': contactIds,
      'is_active': isActive ? 1 : 0, // SQLite는 boolean을 지원하지 않으므로 0/1로 저장
    };
  }

  factory GeofenceEntity.fromMap(Map<String, dynamic> map) {
    return GeofenceEntity(
      id: map['id'] as int?,
      name: map['name'] as String,
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      radius: map['radius'] as double,
      message: map['message'] as String,
      contactIds: map['contact_ids'] as String? ?? '[]',
      isActive: (map['is_active'] as int? ?? 0) == 1,
    );
  }
}
