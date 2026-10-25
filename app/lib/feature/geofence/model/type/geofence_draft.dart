import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_radius.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';

enum GeofenceField { name, address, message, recipients, repeatDays }

/// 서울시청. 현재 위치를 알 수 없을 때의 기본 좌표.
const defaultLatitude = 37.5665;
const defaultLongitude = 126.978;

/// 폼에서 편집 중인 장소. 저장하기 전까지는 DB에 닿지 않는다.
class GeofenceDraft {
  final int? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final GeofenceRadius radius;
  final EventType eventType;
  final GeofenceRepeat repeat;
  final int customDaysBitmask;
  final String message;
  final bool active;
  final Set<String> deviceContactIds;
  final Set<String> serverRecipientKeys;

  const GeofenceDraft({
    this.id,
    this.name = '',
    this.address = '',
    this.latitude = defaultLatitude,
    this.longitude = defaultLongitude,
    this.radius = GeofenceRadius.km1,
    this.eventType = EventType.arrival,
    this.repeat = GeofenceRepeat.none,
    this.customDaysBitmask = 0,
    this.message = '',
    this.active = true,
    this.deviceContactIds = const {},
    this.serverRecipientKeys = const {},
  });

  factory GeofenceDraft.created({
    required double latitude,
    required double longitude,
  }) => GeofenceDraft(
    latitude: latitude,
    longitude: longitude,
    message: defaultMessage('', EventType.arrival),
  );

  factory GeofenceDraft.fromEntity(
    GeofenceEntity entity, {
    required Set<String> deviceContactIds,
    required Set<String> serverRecipientKeys,
  }) => GeofenceDraft(
    id: entity.id,
    name: entity.name,
    address: entity.address,
    latitude: entity.lat,
    longitude: entity.lng,
    radius: GeofenceRadius.fromMeters(entity.radius),
    // 웹 폼은 도착과 출발만 고른다. 예전에 저장된 both는 도착으로 보여 준다.
    eventType: entity.eventType == EventType.departure.name
        ? EventType.departure
        : EventType.arrival,
    repeat: GeofenceRepeat.fromName(entity.repeatType),
    customDaysBitmask: entity.customDaysBitmask ?? 0,
    message: entity.message,
    active: entity.isActive,
    deviceContactIds: deviceContactIds,
    serverRecipientKeys: serverRecipientKeys,
  );

  /// {location}을 그대로 두면 사용자에게 토큰이 보인다. 치환된 문장을 기본값으로 둔다.
  static String defaultMessage(String name, EventType eventType) {
    final location = name.trim().isEmpty ? '장소' : name.trim();
    return eventType == EventType.departure
        ? '안녕하세요! $location에서 출발했습니다.'
        : '안녕하세요! $location에 도착했습니다.';
  }

  bool get hasDeviceRecipients => deviceContactIds.isNotEmpty;

  int get recipientCount =>
      deviceContactIds.length + serverRecipientKeys.length;

  /// 실제로 발송될 SMS 본문. 길이 검증에만 쓴다.
  String get smsBody => composeSmsBody(
    eventType: eventType,
    message: message,
    location: name.trim(),
  );

  GeofenceDraft copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    GeofenceRadius? radius,
    EventType? eventType,
    GeofenceRepeat? repeat,
    int? customDaysBitmask,
    String? message,
    bool? active,
    Set<String>? deviceContactIds,
    Set<String>? serverRecipientKeys,
  }) => GeofenceDraft(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    radius: radius ?? this.radius,
    eventType: eventType ?? this.eventType,
    repeat: repeat ?? this.repeat,
    customDaysBitmask: customDaysBitmask ?? this.customDaysBitmask,
    message: message ?? this.message,
    active: active ?? this.active,
    deviceContactIds: deviceContactIds ?? this.deviceContactIds,
    serverRecipientKeys: serverRecipientKeys ?? this.serverRecipientKeys,
  );

  /// 서버가 거부하는 방향의 편집인지 본다. 이미 한도를 넘긴 상태에서 줄이는 편집까지
  /// 막으면 고칠 방법이 없으므로, 본문이 길어지는 경우만 막는다.
  bool exceedsSmsLimitComparedTo(GeofenceDraft previous) {
    if (!hasDeviceRecipients) return false;
    final length = smsBody.length;
    if (length <= smsBodyMaxLength) return false;
    return length > previous.smsBody.length;
  }

  Map<GeofenceField, String> validate() {
    final errors = <GeofenceField, String>{};
    if (name.trim().isEmpty) errors[GeofenceField.name] = '장소 이름을 입력해 주세요';
    if (address.trim().isEmpty) {
      errors[GeofenceField.address] = '지도에서 장소를 선택해 주세요';
    }
    if (message.trim().isEmpty) {
      errors[GeofenceField.message] = '알림 메시지를 입력해 주세요';
    } else if (hasDeviceRecipients) {
      // 기기 연락처는 서버 SMS로 나가고, 서버는 한도를 넘으면 거부한다.
      final length = smsBody.length;
      if (length > smsBodyMaxLength) {
        errors[GeofenceField.message] =
            '문자 본문이 $smsBodyMaxLength자를 넘었어요. (현재 $length자, 머리말 포함)';
      }
    }
    if (recipientCount == 0) {
      errors[GeofenceField.recipients] = '알림을 받을 사람을 한 명 이상 선택해 주세요';
    }
    if (repeat == GeofenceRepeat.custom && customDaysBitmask == 0) {
      errors[GeofenceField.repeatDays] = '반복할 요일을 하나 이상 골라 주세요';
    }
    return errors;
  }
}
