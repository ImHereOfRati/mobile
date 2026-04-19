import 'dart:convert';
import 'dart:developer';

import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository_provider.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository_provider.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'geofence_view_model_interface.dart';

part 'geofence_view_model.g.dart';

@Riverpod(keepAlive: true)
class GeofenceViewModel extends _$GeofenceViewModel
    implements GeofenceViewModelInterface {
  late PermissionState alwaysStatus;
  late GeofenceLocalRepository _geofenceRepository;
  late GeofenceServerRecipientLocalRepository _serverRecipientRepository;
  late PermissionServiceInterface _locationPermissionService;
  late NativeGeofenceRegistrarInterface _registrar;

  @override
  Future<PermissionState> build() async {
    _geofenceRepository = ref.watch(geofenceLocalRepositoryProvider);
    _serverRecipientRepository = ref.watch(
      geofenceServerRecipientLocalRepositoryProvider,
    );
    _locationPermissionService = ref.watch(locationPermissionServiceProvider);
    _registrar = getIt<NativeGeofenceRegistrarInterface>();
    return await _locationPermissionService.checkPermissionStatus();
  }

  @override
  Future<GeofenceEntity> saveGeofence({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required double radius,
    required String message,
    required List<int> contactIds,
    required List<ServerRecipient> serverRecipients,
  }) async {
    final contactIdsJson = jsonEncode(contactIds);

    final entity = GeofenceEntity(
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      radius: radius,
      message: message,
      contactIds: contactIdsJson,
    );

    final saved = await _geofenceRepository.save(entity);

    if (saved.id != null && serverRecipients.isNotEmpty) {
      for (final r in serverRecipients) {
        await _serverRecipientRepository.save(
          GeofenceServerRecipientEntity(
            geofenceId: saved.id!,
            friendRelationshipId: r.friendRelationshipId,
            friendEmail: r.friendEmail,
            friendAlias: r.friendAlias,
          ),
        );
      }
    }

    return saved;
  }

  @override
  Future<List<GeofenceEntity>> findAllGeofences() async {
    return await _geofenceRepository.findAll();
  }

  @override
  Future<void> toggleGeofenceActive(int id, bool isActive) async {
    await _geofenceRepository.updateActiveStatus(id, isActive);

    if (isActive) {
      try {
        final all = await _geofenceRepository.findAll();
        final entity = all.firstWhere(
          (g) => g.id == id,
          orElse: () => throw StateError('Geofence $id not found'),
        );
        await _registrar.register(entity.copyWith(isActive: true));
      } catch (e) {
        log('toggleGeofenceActive register failed (id=$id): $e');
      }
    } else {
      try {
        await _registrar.unregister(id);
      } catch (e) {
        log('toggleGeofenceActive unregister failed (id=$id): $e');
      }
    }
  }
}
