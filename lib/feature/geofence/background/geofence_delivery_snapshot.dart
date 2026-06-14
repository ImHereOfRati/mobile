import 'dart:convert';

import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

class GeofenceDeliverySnapshot {
  final GeofenceEntity geofence;
  final List<String> recipientNames;
  final List<String> smsPhoneNumbers;
  final List<String> serverEmails;
  final String deliveryEventType;

  const GeofenceDeliverySnapshot({
    required this.geofence,
    required this.recipientNames,
    required this.smsPhoneNumbers,
    required this.serverEmails,
    required this.deliveryEventType,
  });

  Map<String, dynamic> toMap() {
    return {
      'geofence': geofence.toMap(),
      'recipientNames': recipientNames,
      'smsPhoneNumbers': smsPhoneNumbers,
      'serverEmails': serverEmails,
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
      geofence: GeofenceEntity.fromMap(
        Map<String, dynamic>.from(map['geofence'] as Map),
      ),
      recipientNames: List<String>.from(map['recipientNames'] as List),
      smsPhoneNumbers: List<String>.from(map['smsPhoneNumbers'] as List),
      serverEmails: List<String>.from(map['serverEmails'] as List),
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
