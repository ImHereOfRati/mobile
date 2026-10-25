import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/geofence/model/dto/place_search_result_dto.dart';
import 'package:iamhere/feature/geofence/model/dto/reverse_geocode_dto.dart';
import 'package:iamhere/feature/geofence/model/repository/map_proxy_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class MapSearchService {
  final MapProxyRepository _repository;

  MapSearchService(this._repository);

  /// 장소 이름으로 검색해 좌표가 있는 후보만 돌려준다. 한 후보의 좌표 변환이
  /// 실패해도 나머지는 살린다.
  Future<List<PlaceSearchResultDto>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final items = await _repository.localSearch(trimmed);
    final resolved = await Future.wait(items.map(_resolve));
    return resolved.whereType<PlaceSearchResultDto>().toList(growable: false);
  }

  Future<PlaceSearchResultDto?> _resolve(LocalSearchItem item) async {
    final address = _firstNotEmpty(item.roadAddress, item.address);
    if (address == null) return null;
    try {
      final coordinate = await _repository.geocode(address);
      if (coordinate == null) return null;
      return PlaceSearchResultDto(
        title: stripHtml(item.title),
        address:
            _firstNotEmpty(coordinate.roadAddress, coordinate.jibunAddress) ??
            address,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );
    } catch (error, stack) {
      AppLogger.error('Place geocoding failed', error, stack);
      return null;
    }
  }

  /// 좌표의 주소. 실패하면 null이라 호출한 쪽이 사용자가 입력한 값을 지키고
  /// 지나갈 수 있다.
  Future<ReverseGeocodeDto?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _repository.reverseGeocode(latitude, longitude);
    } catch (error, stack) {
      AppLogger.error('Reverse geocoding failed', error, stack);
      return null;
    }
  }

  /// 네이버 검색은 제목에 강조용 태그와 HTML 엔티티를 섞어 준다.
  static String stripHtml(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  static String? _firstNotEmpty(String? a, String? b) {
    if (a != null && a.isNotEmpty) return a;
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
