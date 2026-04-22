import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/utils/radius_helper.dart';
import 'geofence_basic_info.dart';
import 'geofence_area_info.dart';
import 'geofence_status_info.dart';
export 'geofence_basic_info.dart';
export 'geofence_area_info.dart';
export 'geofence_status_info.dart';

class GeofenceEnrollFormState {
  final GeofenceBasicInfo basic;
  final GeofenceAreaInfo area;
  final GeofenceStatusInfo status;

  GeofenceEnrollFormState({
    this.basic = const GeofenceBasicInfo(),
    this.area = const GeofenceAreaInfo(),
    this.status = const GeofenceStatusInfo(),
  });

  String get radiusInfoMessage {
    final radiusValue = int.tryParse(area.radius);
    if (radiusValue == null) return '';
    return RadiusHelper.getRadiusInfoMessage(radiusValue);
  }

  GeofenceEnrollFormState copyWith({
    GeofenceBasicInfo? basic,
    GeofenceAreaInfo? area,
    GeofenceStatusInfo? status,
  }) {
    return GeofenceEnrollFormState(
      basic: basic ?? this.basic,
      area: area ?? this.area,
      status: status ?? this.status,
    );
  }

  // Helper getters to minimize UI changes
  String get name => basic.name;
  String get address => basic.address;
  String get message => basic.message;
  NLatLng? get selectedLocation => area.location;
  String get radius => area.radius;
  List<Recipient> get selectedRecipients => status.recipients;
  bool get isActive => status.isActive;
}
