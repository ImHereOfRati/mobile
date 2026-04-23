import 'dart:convert';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:iamhere/feature/friend/repository/contact_local_repository_provider.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/service/geocoding_service_provider.dart';
import 'package:iamhere/feature/geofence/view_model/dto/save_geofence_request.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'geofence_enroll_form_state.dart';
import 'geofence_form_validator.dart';
import '../main/geofence_view_model_provider.dart';

part 'geofence_enroll_view_model.g.dart';

@Riverpod(keepAlive: false)
class GeofenceEnrollViewModel extends _$GeofenceEnrollViewModel {
  int? _id;

  @override
  GeofenceEnrollFormState build() => GeofenceEnrollFormState();

  void initializeWithGeofence(
    GeofenceEntity geofence,
    List<ServerRecipient> serverRecipients,
  ) async {
    _id = geofence.id;
    state = state.copyWith(
      basic: state.basic.copyWith(
        name: geofence.name,
        address: geofence.address,
        message: geofence.message,
      ),
      area: state.area.copyWith(
        location: NLatLng(geofence.lat, geofence.lng),
        radius: geofence.radius.toInt().toString(),
      ),
      status: state.status.copyWith(
        isActive: geofence.isActive,
      ),
    );

    // 수신자 목록 초기화
    final List<int> contactIds = jsonDecode(geofence.contactIds).cast<int>();
    final contactRepo = ref.read(contactLocalRepositoryProvider);
    final allContacts = await contactRepo.findAll();
    final localRecipients = allContacts
        .where((c) => contactIds.contains(c.id))
        .map((c) => LocalRecipient(Contact(id: c.id, name: c.name, number: c.number)))
        .toList();

    state = state.copyWith(
      status: state.status.copyWith(
        recipients: [...localRecipients, ...serverRecipients],
      ),
    );
  }

  void updateName(String name) =>
      state = state.copyWith(basic: state.basic.copyWith(name: name));

  Future<void> updateLocation(NLatLng? location) async {
    state = state.copyWith(area: state.area.copyWith(location: location));
    if (location != null) {
      final address = await ref
          .read(geocodingServiceProvider)
          .reverseGeocode(location.latitude, location.longitude);
      state = state.copyWith(basic: state.basic.copyWith(address: address));
    }
  }

  void updateAddress(String address) =>
      state = state.copyWith(basic: state.basic.copyWith(address: address));
  void updateRadius(String radius) =>
      state = state.copyWith(area: state.area.copyWith(radius: radius));
  void updateRecipients(List<Recipient> r) =>
      state = state.copyWith(status: state.status.copyWith(recipients: r));
  void updateMessage(String m) =>
      state = state.copyWith(basic: state.basic.copyWith(message: m));
  void updateIsActive(bool a) =>
      state = state.copyWith(status: state.status.copyWith(isActive: a));
  void resetForm() => state = GeofenceEnrollFormState();

  Future<void> saveGeofence() async {
    final res = GeofenceFormValidator.validate(state);
    if (!res.isValid) throw Exception(res.errorMessage ?? '입력값을 확인해주세요');

    final contactIds = state.selectedRecipients
        .whereType<LocalRecipient>()
        .where((r) => r.id != null)
        .map((r) => r.id!)
        .toList();
    final serverRecipients =
        state.selectedRecipients.whereType<ServerRecipient>().toList();

    final vm = ref.read(geofenceViewModelInterfaceProvider);
    final saved = await vm.saveGeofence(SaveGeofenceRequest(
      id: _id,
      name: state.name.trim(),
      address: state.address.trim(),
      lat: state.selectedLocation!.latitude,
      lng: state.selectedLocation!.longitude,
      radius: double.parse(state.radius.trim()),
      message: state.message.trim(),
      contactIds: contactIds,
      serverRecipients: serverRecipients,
    ));

    if (state.isActive && saved.id != null) {
      await vm.toggleGeofenceActive(saved.id!, true);
    }
  }
}
