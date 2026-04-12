import 'dart:convert';

import 'package:iamhere/geofence/repository/geofence_entity.dart';
import 'package:iamhere/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/geofence/repository/geofence_local_repository_provider.dart';
import 'package:iamhere/geofence/view_model/geofence_view_model_interface.dart';
import 'package:iamhere/user_permission/model/permission_state.dart';
import 'package:iamhere/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/user_permission/service/permission_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'geofence_view_model.g.dart';

@Riverpod(keepAlive: true)
class GeofenceViewModel extends _$GeofenceViewModel
    implements GeofenceViewModelInterface {
  late PermissionState alwaysStatus;
  late GeofenceLocalRepository _geofenceRepository;
  late PermissionServiceInterface _locationPermissionService;

  @override
  Future<PermissionState> build() async {
    _geofenceRepository = ref.watch(geofenceLocalRepositoryProvider);
    _locationPermissionService = ref.watch(locationPermissionServiceProvider);
    return await _locationPermissionService.checkPermissionStatus();
  }

  @override
  Future<GeofenceEntity> saveGeofence({
    required String name,
    required double lat,
    required double lng,
    required double radius,
    required String message,
    required List<int> contactIds,
  }) async {
    // 연락처 ID 리스트를 JSON 문자열로 변환
    final contactIdsJson = jsonEncode(contactIds);

    final entity = GeofenceEntity(
      name: name,
      lat: lat,
      lng: lng,
      radius: radius,
      message: message,
      contactIds: contactIdsJson,
    );

    return await _geofenceRepository.save(entity);
  }

  @override
  Future<List<GeofenceEntity>> findAllGeofences() async {
    return await _geofenceRepository.findAll();
  }

  @override
  Future<void> toggleGeofenceActive(int id, bool isActive) async {
    await _geofenceRepository.updateActiveStatus(id, isActive);
  }
}
