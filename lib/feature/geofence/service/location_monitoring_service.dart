import 'dart:async';
import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
import 'package:injectable/injectable.dart';

/// Location monitoring and permission handling
@lazySingleton
class LocationMonitoringService {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Start listening to location updates
  /// Throws exception if location permission is not granted
  Future<Stream<Position>> startLocationMonitoring(
    Function(Position position) onPositionUpdate,
  ) async {
    // Stop any existing monitoring
    await stopLocationMonitoring();

    log('Starting location monitoring');

    try {
      final locationService = LocatePermissionService();
      final permissionState = await locationService
          .requestLocationPermissions();

      if (permissionState != PermissionState.grantedAlways &&
          permissionState != PermissionState.grantedWhenInUse) {
        log('Location permission not granted: ${permissionState.name}');
        throw Exception(
          'Location permission required. Please enable location access in settings.',
        );
      }

      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              onPositionUpdate(position);
            },
            onError: (error) {
              log('Location stream error: $error');
            },
          );

      log('Location monitoring started');
      return Geolocator.getPositionStream(locationSettings: locationSettings);
    } catch (e) {
      log('Failed to start location monitoring: $e');
      rethrow;
    }
  }

  /// Stop listening to location updates
  Future<void> stopLocationMonitoring() async {
    log('Stopping location monitoring');
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
