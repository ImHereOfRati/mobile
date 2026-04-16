/// 네이버 Local Search API 응답 모델
class PlaceSearchResult {
  final String title;
  final String address;
  final String roadAddress;
  final double latitude;
  final double longitude;
  final String category;

  PlaceSearchResult({
    required this.title,
    required this.address,
    required this.roadAddress,
    required this.latitude,
    required this.longitude,
    required this.category,
  });

  /// 표시용 주소 (도로명 우선)
  String get displayAddress =>
      roadAddress.isNotEmpty ? roadAddress : address;

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    // Naver Local Search API의 좌표는 KATECH (TM128) 좌표계
    // mapx, mapy를 경위도로 변환 필요
    final rawTitle = (json['title'] as String? ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), ''); // HTML 태그 제거

    return PlaceSearchResult(
      title: rawTitle,
      address: json['address'] as String? ?? '',
      roadAddress: json['roadAddress'] as String? ?? '',
      latitude: _katechToLatitude(json['mapy'] as String? ?? '0'),
      longitude: _katechToLongitude(json['mapx'] as String? ?? '0'),
      category: json['category'] as String? ?? '',
    );
  }

  /// KATECH Y → 위도 (간이 변환 – Naver API 좌표는 실제로 경위도×10^7 형식)
  static double _katechToLatitude(String mapy) {
    final value = int.tryParse(mapy) ?? 0;
    // Naver Local Search의 mapy는 실제로 WGS84 위도 * 10^7
    return value / 10000000.0;
  }

  /// KATECH X → 경도 (간이 변환)
  static double _katechToLongitude(String mapx) {
    final value = int.tryParse(mapx) ?? 0;
    return value / 10000000.0;
  }
}
