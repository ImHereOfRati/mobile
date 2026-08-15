import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity_mapper.dart';

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
  final bool awaitingDeparture; // both 알림의 도착 이후 출발 대기 상태
  final int serverRecipientCount; // IMHERE 서버 친구 숫자
  final String eventType; // EventType enum name (arrival/departure/both)
  final String
  repeatType; // RepeatType enum name (none/daily/weekday/weekend/custom)
  final int?
  customDaysBitmask; // Bitmask for custom days (only if repeatType == custom)

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
    this.awaitingDeparture = false,
    this.serverRecipientCount = 0, // 기본값 0 보장
    this.eventType = 'arrival',
    this.repeatType = 'none',
    this.customDaysBitmask,
  });

  /// SMS 발송 시 사용할 location 문자열: "장소명 (주소)"
  String get fullLocation => composeFullLocation(name, address);

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
    bool? awaitingDeparture,
    int? serverRecipientCount,
    String? eventType,
    String? repeatType,
    int? customDaysBitmask,
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
      awaitingDeparture: awaitingDeparture ?? this.awaitingDeparture,
      serverRecipientCount: serverRecipientCount ?? this.serverRecipientCount,
      eventType: eventType ?? this.eventType,
      repeatType: repeatType ?? this.repeatType,
      customDaysBitmask: customDaysBitmask ?? this.customDaysBitmask,
    );
  }

  Map<String, dynamic> toMap() {
    return const GeofenceEntityMapper().toDatabaseMap(this);
  }

  factory GeofenceEntity.fromMap(Map<String, dynamic> map) {
    return const GeofenceEntityMapper().fromDatabaseMap(map);
  }
}
