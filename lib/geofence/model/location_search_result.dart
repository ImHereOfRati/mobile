/// 통합 검색 결과 모델 (Geocoding + Local Search 결과를 통합)
class LocationSearchResult {
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final LocationSearchType type;

  LocationSearchResult({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
  });
}

enum LocationSearchType {
  /// 주소 기반 검색 결과 (Geocoding API)
  address,

  /// 장소명 기반 검색 결과 (Local Search API)
  place,
}
