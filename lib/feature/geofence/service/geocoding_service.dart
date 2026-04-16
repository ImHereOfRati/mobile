import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iamhere/feature/geofence/model/geocoding_result.dart';
import 'package:iamhere/feature/geofence/model/place_search_result.dart';

import '../model/location_search_result.dart';

/// 네이버 Geocoding API + Local Search API 통합 위치 검색 서비스
class GeocodingService {
  static const _geocodeUrl =
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode';
  static const _reverseGeocodeUrl =
      'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc';
  static const _localSearchUrl =
      'https://openapi.naver.com/v1/search/local.json';

  final Dio _dio;

  GeocodingService() : _dio = Dio();

  /// Reverse Geocoding: 좌표 → 주소
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';

      final response = await _dio.get(
        _reverseGeocodeUrl,
        queryParameters: {'coords': '$lng,$lat', 'output': 'json'},
        options: Options(
          headers: {
            'x-ncp-apigw-api-key-id': clientId,
            'x-ncp-apigw-api-key': clientSecret,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        if (results.isNotEmpty) {
          final result = results[0] as Map<String, dynamic>;
          final region = result['region'] as Map<String, dynamic>? ?? {};

          final area1 = region['area1']?['name'] ?? ''; // 시/도
          final area2 = region['area2']?['name'] ?? ''; // 시/군/구

          return '$area1 $area2'.trim();
        }
      }
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    } catch (e) {
      log('Reverse geocoding error: $e');
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  /// 통합 검색: Geocoding(주소) + Local Search(장소명)를 병렬로 실행
  Future<List<LocationSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await Future.wait([
      _searchByGeocode(query),
      _searchByPlace(query),
    ]);

    final geocodeResults = results[0];
    final placeResults = results[1];

    // 장소 검색 결과를 먼저, 주소 검색 결과를 뒤에 배치
    return [...placeResults, ...geocodeResults];
  }

  /// Geocoding API로 주소 검색
  Future<List<LocationSearchResult>> _searchByGeocode(String query) async {
    try {
      final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['NAVER_MAP_CLIENT_SECRET'] ?? '';

      final response = await _dio.get(
        _geocodeUrl,
        queryParameters: {'query': query},
        options: Options(
          headers: {
            'X-NCP-APIGW-API-KEY-ID': clientId,
            'X-NCP-APIGW-API-KEY': clientSecret,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>? ?? [];
        return addresses.map((e) {
          final geo = GeocodingResult.fromJson(e as Map<String, dynamic>);
          return LocationSearchResult(
            title: geo.displayAddress,
            address: geo.jibunAddress.isNotEmpty
                ? geo.jibunAddress
                : geo.roadAddress,
            latitude: geo.latitude,
            longitude: geo.longitude,
            type: LocationSearchType.address,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      log('Geocoding search error: $e');
      return [];
    }
  }

  /// Naver Local Search API로 장소 검색
  Future<List<LocationSearchResult>> _searchByPlace(String query) async {
    try {
      final clientId = dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '';

      // 키가 없으면 스킵
      if (clientId.isEmpty || clientSecret.isEmpty) return [];

      final response = await _dio.get(
        _localSearchUrl,
        queryParameters: {'query': query, 'display': 5},
        options: Options(
          headers: {
            'X-Naver-Client-Id': clientId,
            'X-Naver-Client-Secret': clientSecret,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map((e) {
              final place = PlaceSearchResult.fromJson(
                e as Map<String, dynamic>,
              );
              return LocationSearchResult(
                title: place.title,
                address: place.displayAddress,
                latitude: place.latitude,
                longitude: place.longitude,
                type: LocationSearchType.place,
              );
            })
            .where((r) => r.latitude != 0 && r.longitude != 0)
            .toList();
      }
      return [];
    } catch (e) {
      log('Local search error: $e');
      return [];
    }
  }
}
