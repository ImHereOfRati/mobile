import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/model/repeat_schedule.dart';

class GeofenceStatusInfo {
  final List<Recipient> recipients;
  final bool isActive;
  final RepeatSchedule repeatSchedule;

  const GeofenceStatusInfo({
    this.recipients = const [],
    this.isActive = true,
    this.repeatSchedule = const RepeatSchedule(),
  });

  GeofenceStatusInfo copyWith({
    List<Recipient>? recipients,
    bool? isActive,
    RepeatSchedule? repeatSchedule,
  }) {
    return GeofenceStatusInfo(
      recipients: recipients ?? this.recipients,
      isActive: isActive ?? this.isActive,
      repeatSchedule: repeatSchedule ?? this.repeatSchedule,
    );
  }
}
