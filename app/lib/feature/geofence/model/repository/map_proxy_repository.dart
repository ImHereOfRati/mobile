import 'package:dio/dio.dart';
import 'package:iamhere/feature/geofence/model/dto/reverse_geocode_dto.dart';
import 'package:injectable/injectable.dart';

/// 네이버 장소 검색과 지오코딩을 서버 프록시로 부른다. 네이버 시크릿 키는 서버에만
/// 있고, 앱에는 넣지 않는다.
@lazySingleton
class MapProxyRepository {
  static const _localSearchPath = '/api/maps/local-search';
  static const _geocodePath = '/api/maps/geocode';
  static const _reverseGeocodePath = '/api/maps/reverse-geocode';

  final Dio _dio;

  MapProxyRepository(this._dio);

  static final _authenticated = Options(
    extra: const {'requiresAuthentication': true},
  );

  /// 장소 이름으로 검색한 후보. 좌표는 아직 없다.
  Future<List<LocalSearchItem>> localSearch(String query) async {
    final data = await _data(
      _localSearchPath,
      {'query': query},
    );
    final items = data['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => LocalSearchItem.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// 주소를 좌표로 바꾼다. 결과가 없으면 null.
  Future<GeocodedAddress?> geocode(String address) async {
    final data = await _data(_geocodePath, {'query': address});
    final addresses = data['addresses'];
    if (addresses is! List || addresses.isEmpty || addresses.first is! Map) {
      return null;
    }
    return GeocodedAddress.fromJson(
      (addresses.first as Map).cast<String, dynamic>(),
    );
  }

  Future<ReverseGeocodeDto> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final data = await _data(_reverseGeocodePath, {
      'latitude': latitude,
      'longitude': longitude,
    });
    return ReverseGeocodeDto.fromJson(data);
  }

  Future<Map<String, dynamic>> _data(
    String path,
    Map<String, Object> query,
  ) async {
    final response = await _dio.get(
      path,
      queryParameters: query,
      options: _authenticated,
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic> || raw['data'] is! Map) {
      throw StateError('지도 응답 형식이 올바르지 않습니다.');
    }
    return (raw['data'] as Map).cast<String, dynamic>();
  }
}

class LocalSearchItem {
  final String title;
  final String? address;
  final String? roadAddress;

  const LocalSearchItem({
    required this.title,
    required this.address,
    required this.roadAddress,
  });

  factory LocalSearchItem.fromJson(Map<String, dynamic> json) =>
      LocalSearchItem(
        title: json['title'] as String? ?? '',
        address: json['address'] as String?,
        roadAddress: json['roadAddress'] as String?,
      );
}

class GeocodedAddress {
  final String? roadAddress;
  final String? jibunAddress;
  final double latitude;
  final double longitude;

  const GeocodedAddress({
    required this.roadAddress,
    required this.jibunAddress,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodedAddress.fromJson(Map<String, dynamic> json) =>
      GeocodedAddress(
        roadAddress: json['roadAddress'] as String?,
        jibunAddress: json['jibunAddress'] as String?,
        // 네이버는 x가 경도, y가 위도이고 문자열로 준다.
        longitude: double.parse(json['x'].toString()),
        latitude: double.parse(json['y'].toString()),
      );
}
