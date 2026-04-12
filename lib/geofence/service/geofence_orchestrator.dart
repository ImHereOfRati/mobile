import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/geofence/service/contact_resolution_service.dart';
import 'package:iamhere/geofence/service/deduplication_service.dart';
import 'package:iamhere/geofence/service/geofence_checking_service.dart';
import 'package:iamhere/geofence/service/location_monitoring_service.dart';
import 'package:iamhere/geofence/service/record_service.dart';
import 'package:iamhere/geofence/service/sms_notification_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_orchestrator.g.dart';

/// Orchestrates geofence monitoring by coordinating multiple services
/// Replaces GeofenceMonitoringService with clean separation of concerns
@Riverpod(keepAlive: true)
class GeofenceOrchestrator extends _$GeofenceOrchestrator {
  late LocationMonitoringService _locationService;
  late GeofenceCheckingService _geofenceChecker;
  late ContactResolutionService _contactResolver;
  late SmsNotificationService _smsNotifier;
  late RecordService _recordService;
  late DeduplicationService _deduplicationService;
  late GeofenceLocalRepository _geofenceRepository;

  @override
  Future<void> build() async {
    // Services will be injected via ref.watch() when monitoring starts
  }

  /// Start monitoring geofences
  Future<void> startMonitoring() async {
    await stopMonitoring();

    log('Starting geofence monitoring orchestration');

    try {
      // Inject services (using GetIt since they're registered there)
      _setupServices();

      // Start location monitoring
      await _locationService.startLocationMonitoring((Position position) async {
        await _checkGeofences(position);
      });

      log('Geofence monitoring orchestration started');
    } catch (e) {
      log('Failed to start geofence monitoring: $e');
      rethrow;
    }
  }

  /// Stop monitoring geofences
  Future<void> stopMonitoring() async {
    log('Stopping geofence monitoring orchestration');
    await _locationService.stopLocationMonitoring();
    _deduplicationService.reset();
  }

  /// Check geofences for current position
  Future<void> _checkGeofences(Position currentPosition) async {
    try {
      final allGeofences = await _geofenceRepository.findAll();
      final activeGeofences = allGeofences.where((g) => g.isActive).toList();

      for (final geofence in activeGeofences) {
        // Skip if already triggered (deduplication)
        if (_deduplicationService.isDuplicate(geofence.id ?? -1)) {
          continue;
        }

        // Check if within geofence
        if (_geofenceChecker.isWithinGeofence(currentPosition, geofence)) {
          log('Geofence entry detected: ${geofence.name}');

          // Mark as triggered to prevent duplicates
          if (geofence.id != null) {
            _deduplicationService.markTriggered(geofence.id!);
          }

          // Resolve contacts and send SMS
          final recipients = await _contactResolver.resolveContacts(geofence);
          if (recipients.isNotEmpty) {
            final phoneNumbers = _contactResolver.extractPhoneNumbers(
              recipients,
            );
            final result = await _smsNotifier.sendSmsToRecipients(
              phoneNumbers: phoneNumbers,
              message: geofence.message,
            );

            // If SMS successful, save record and deactivate geofence
            if (result is Success) {
              await _recordService.saveGeofenceRecord(
                geofence: geofence,
                recipients: recipients,
              );

              // Deactivate geofence (via repository, not ViewModel)
              if (geofence.id != null) {
                try {
                  await _geofenceRepository.updateActiveStatus(
                    geofence.id!,
                    false,
                  );
                  log('Geofence deactivated: ${geofence.name}');
                } catch (e) {
                  log('Failed to deactivate geofence: $e');
                }
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error checking geofences: $e');
    }
  }

  /// Setup all required services from GetIt
  void _setupServices() {
    final getIt = GetIt.instance;
    _locationService = getIt<LocationMonitoringService>();
    _geofenceChecker = getIt<GeofenceCheckingService>();
    _contactResolver = getIt<ContactResolutionService>();
    _smsNotifier = getIt<SmsNotificationService>();
    _recordService = getIt<RecordService>();
    _deduplicationService = getIt<DeduplicationService>();
    _geofenceRepository = getIt<GeofenceLocalRepository>();
  }
}
