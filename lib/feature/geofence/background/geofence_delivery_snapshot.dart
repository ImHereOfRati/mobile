import 'dart:convert';

import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';

class GeofenceDeliverySnapshot {
  final GeofenceEntity geofence;
  final List<String> recipientNames;
  final List<String> smsPhoneNumbers;
  final List<String> serverEmails;
  final String eventName;

  const GeofenceDeliverySnapshot({
    required this.geofence,
    required this.recipientNames,
    required this.smsPhoneNumbers,
    required this.serverEmails,
    required this.eventName,
  });

  Map<String, dynamic> toMap() {
    return {
      'geofence': geofence.toMap(),
      'recipientNames': recipientNames,
      'smsPhoneNumbers': smsPhoneNumbers,
      'serverEmails': serverEmails,
      'eventName': eventName,
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
      eventName: map['eventName'] as String? ?? 'enter',
    );
  }
}
