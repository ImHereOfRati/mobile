import 'dart:convert';
import 'dart:developer';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:iamhere/feature/geofence/view_model/dto/save_geofence_request.dart';
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
class GeofenceViewModel extends _$GeofenceViewModel implements GeofenceViewModelInterface {
  late GeofenceLocalRepository _repo;
  late GeofenceServerRecipientLocalRepository _srvRepo;
  late PermissionServiceInterface _permSrv;
  late NativeGeofenceRegistrarInterface _reg;
  late FcmNotificationService _fcm;

  @override
  Future<PermissionState> build() async {
    _repo = ref.watch(geofenceLocalRepositoryProvider);
    _srvRepo = ref.watch(geofenceServerRecipientLocalRepositoryProvider);
    _permSrv = ref.watch(locationPermissionServiceProvider);
    _reg = getIt<NativeGeofenceRegistrarInterface>();
    _fcm = getIt<FcmNotificationService>();
    return await _permSrv.checkPermissionStatus();
  }

  @override
  Future<GeofenceEntity> saveGeofence(SaveGeofenceRequest request) async {
    final saved = await _repo.save(GeofenceEntity(
      name: request.name,
      address: request.address,
      lat: request.lat,
      lng: request.lng,
      radius: request.radius,
      message: request.message,
      contactIds: jsonEncode(request.contactIds),
    ));
    if (saved.id != null) {
      for (final r in request.serverRecipients) {
        await _srvRepo.save(GeofenceServerRecipientEntity(
          geofenceId: saved.id!,
          friendRelationshipId: r.friendRelationshipId,
          friendEmail: r.friendEmail,
          friendAlias: r.friendAlias,
        ));
        _fcm.notifyLocationTarget(
          receiverEmail: r.friendEmail,
          type: 'LOCATION_TARGET',
          body: '위치 알림 대상자로 등록되었습니다.',
        );
      }
    }
    return saved;
  }

  @override
  Future<List<GeofenceEntity>> findAllGeofences() => _repo.findAll();

  @override
  Future<void> toggleGeofenceActive(int id, bool isActive) async {
    await _repo.updateActiveStatus(id, isActive);
    try {
      if (isActive) {
        final all = await _repo.findAll();
        final g = all.firstWhere((g) => g.id == id);
        await _reg.register(g.copyWith(isActive: true));
      } else {
        await _reg.unregister(id);
      }
    } catch (e) { log('toggleGeofenceActive failed (id=$id): $e'); }
  }
}
