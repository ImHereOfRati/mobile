import 'package:iamhere/feature/geofence/service/geocoding_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geocoding_service_provider.g.dart';

@riverpod
GeocodingService geocodingService(Ref ref) {
  return GeocodingService();
}
