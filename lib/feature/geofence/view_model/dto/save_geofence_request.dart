import 'package:iamhere/feature/geofence/model/recipient.dart';

class SaveGeofenceRequest {
  final int? id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double radius;
  final String message;
  final List<int> contactIds;
  final List<ServerRecipient> serverRecipients;

  SaveGeofenceRequest({
    this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.message,
    required this.contactIds,
    required this.serverRecipients,
  });
}
