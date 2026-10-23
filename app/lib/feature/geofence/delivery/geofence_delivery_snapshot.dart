import 'dart:convert';

import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity_mapper.dart';

class GeofenceDeliverySnapshot {
  static const _geofenceMapper = GeofenceEntityMapper();

  final GeofenceEntity geofence;
  final List<String> recipientNames;
  final List<String> smsPhoneNumbers;
  final List<String> serverUserIds;
  final String deliveryEventType;

  const GeofenceDeliverySnapshot({
    required this.geofence,
    required this.recipientNames,
    required this.smsPhoneNumbers,
    required this.serverUserIds,
    required this.deliveryEventType,
  });

  Map<String, dynamic> toMap() {
    return {
      'geofence': _geofenceMapper.toDatabaseMap(geofence),
      'recipientNames': recipientNames,
      'smsPhoneNumbers': smsPhoneNumbers,
      'serverUserIds': serverUserIds,
      'deliveryEventType': deliveryEventType,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory GeofenceDeliverySnapshot.fromJson(String json) {
    return GeofenceDeliverySnapshot.fromMap(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );
  }

  factory GeofenceDeliverySnapshot.fromMap(Map<String, dynamic> map) {
    return GeofenceDeliverySnapshot(
      geofence: _geofenceMapper.fromDatabaseMap(
        Map<String, dynamic>.from(map['geofence'] as Map),
      ),
      recipientNames: List<String>.from(map['recipientNames'] as List),
      smsPhoneNumbers: List<String>.from(map['smsPhoneNumbers'] as List),
      serverUserIds: List<String>.from(
        (map['serverUserIds'] ?? map['serverEmails'] ?? const []) as List,
      ),
      deliveryEventType: _normalizeStoredDeliveryEventType(
        map['deliveryEventType'] as String? ?? map['eventName'] as String?,
      ),
    );
  }

  static String _normalizeStoredDeliveryEventType(String? raw) {
    switch (raw) {
      case 'departure':
      case 'exit':
        return 'departure';
      case 'arrival':
      case 'enter':
      case 'dwell':
      default:
        return 'arrival';
    }
  }
}
