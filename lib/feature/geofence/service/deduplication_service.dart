import 'package:injectable/injectable.dart';

/// Deduplication service to prevent multiple triggers for the same geofence
@lazySingleton
class DeduplicationService {
  final Set<int> _enteredGeofenceIds = {};

  /// Check if a geofence has already been triggered
  bool isDuplicate(int geofenceId) {
    return _enteredGeofenceIds.contains(geofenceId);
  }

  /// Mark a geofence as triggered
  void markTriggered(int geofenceId) {
    _enteredGeofenceIds.add(geofenceId);
  }

  /// Reset deduplication state (when monitoring stops)
  void reset() {
    _enteredGeofenceIds.clear();
  }
}
