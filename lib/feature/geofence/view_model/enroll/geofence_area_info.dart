import 'package:flutter_naver_map/flutter_naver_map.dart';

class GeofenceAreaInfo {
  final NLatLng? location;
  final String radius;

  const GeofenceAreaInfo({
    this.location,
    this.radius = '500',
  });

  GeofenceAreaInfo copyWith({
    NLatLng? location,
    String? radius,
  }) {
    return GeofenceAreaInfo(
      location: location ?? this.location,
      radius: radius ?? this.radius,
    );
  }
}
