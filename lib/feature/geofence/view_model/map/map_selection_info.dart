import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapSelectionInfo {
  final NLatLng? location;
  final String address;

  const MapSelectionInfo({
    this.location,
    this.address = '',
  });

  MapSelectionInfo copyWith({
    NLatLng? location,
    String? address,
  }) {
    return MapSelectionInfo(
      location: location ?? this.location,
      address: address ?? this.address,
    );
  }
}
