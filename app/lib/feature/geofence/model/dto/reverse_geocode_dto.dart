import 'package:iamhere/feature/geofence/model/location_label_formatter.dart';

/// 좌표를 주소로 바꾼 결과. 서버 프록시가 네이버 응답을 그대로 전달한다.
class ReverseGeocodeDto {
  final String? placeName;
  final List<String> regions;
  final String landName;
  final String landNumber;

  const ReverseGeocodeDto({
    required this.placeName,
    required this.regions,
    required this.landName,
    required this.landNumber,
  });

  /// 응답에 결과가 하나도 없을 때.
  const ReverseGeocodeDto.empty()
    : placeName = null,
      regions = const [],
      landName = '',
      landNumber = '';

  factory ReverseGeocodeDto.fromJson(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List || results.isEmpty || results.first is! Map) {
      return const ReverseGeocodeDto.empty();
    }
    final first = (results.first as Map).cast<String, dynamic>();
    final region = (first['region'] as Map?)?.cast<String, dynamic>() ?? {};
    final regionNames = <String>[];
    for (final key in ['area1', 'area2', 'area3', 'area4']) {
      final name = ((region[key] as Map?)?['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) regionNames.add(name);
    }
    final land = (first['land'] as Map?)?.cast<String, dynamic>() ?? {};
    final number = [
      land['number1'] as String? ?? '',
      land['number2'] as String? ?? '',
    ].where((part) => part.isNotEmpty).join('-');
    return ReverseGeocodeDto(
      placeName: (first['name'] as String?)?.trim(),
      regions: regionNames,
      landName: (land['name'] as String?)?.trim() ?? '',
      landNumber: number,
    );
  }

  /// 시/도와 시/군/구만 담은 짧은 이름. 이미 저장된 장소의 빈 주소를 채울 때 쓴다.
  String shortLabel(double latitude, double longitude) {
    final label = regions.take(2).join(' ');
    return label.isEmpty ? fallbackCoordinates(latitude, longitude) : label;
  }

  /// 도로명, 번지까지 이어 붙인 전체 주소.
  String fullAddress(double latitude, double longitude) {
    final parts = [...regions, landName, landNumber].where((p) => p.isNotEmpty);
    final address = parts.join(' ');
    return address.isEmpty ? fallbackCoordinates(latitude, longitude) : address;
  }
}
