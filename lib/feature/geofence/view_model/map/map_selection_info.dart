import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapSelectionInfo {
  final NLatLng? location;
  final String name;
  final String address;

  const MapSelectionInfo({this.location, this.name = '', this.address = ''});

  MapSelectionInfo copyWith({
    NLatLng? location,
    String? name,
    String? address,
  }) {
    return MapSelectionInfo(
      location: location ?? this.location,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }
}
