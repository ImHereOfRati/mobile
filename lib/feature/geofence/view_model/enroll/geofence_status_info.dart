import 'package:iamhere/feature/geofence/model/recipient.dart';

class GeofenceStatusInfo {
  final List<Recipient> recipients;
  final bool isActive;

  const GeofenceStatusInfo({
    this.recipients = const [],
    this.isActive = true,
  });

  GeofenceStatusInfo copyWith({
    List<Recipient>? recipients,
    bool? isActive,
  }) {
    return GeofenceStatusInfo(
      recipients: recipients ?? this.recipients,
      isActive: isActive ?? this.isActive,
    );
  }
}
