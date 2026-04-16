/// 네이버 Geocoding API 응답 모델
class GeocodingResult {
  final String roadAddress;
  final String jibunAddress;
  final double latitude;
  final double longitude;

  GeocodingResult({
    required this.roadAddress,
    required this.jibunAddress,
    required this.latitude,
    required this.longitude,
  });

  /// 표시용 주소 (도로명 우선, 없으면 지번)
  String get displayAddress =>
      roadAddress.isNotEmpty ? roadAddress : jibunAddress;

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      roadAddress: json['roadAddress'] as String? ?? '',
      jibunAddress: json['jibunAddress'] as String? ?? '',
      latitude: double.tryParse(json['y']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['x']?.toString() ?? '') ?? 0.0,
    );
  }
}
