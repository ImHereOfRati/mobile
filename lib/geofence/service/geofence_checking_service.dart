import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:iamhere/geofence/repository/geofence_entity.dart';
import 'package:injectable/injectable.dart';

/// Geofence boundary checking and distance calculation
@lazySingleton
class GeofenceCheckingService {
  /// Check if current position is within geofence radius
  bool isWithinGeofence(Position currentPosition, GeofenceEntity geofence) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      geofence.lat,
      geofence.lng,
    );
    return distance <= geofence.radius;
  }

  /// Calculate distance in meters between two coordinates
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
