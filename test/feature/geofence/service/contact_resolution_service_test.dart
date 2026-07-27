import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/repository/contact_entity.dart';
import 'package:iamhere/feature/friend/repository/contact_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository.dart';
import 'package:iamhere/feature/geofence/service/contact_resolution_service.dart';

void main() {
  test('resolves string contact ids saved by the React bridge', () async {
    final service = ContactResolutionService(_Contacts(), _Recipients());
    final geofence = GeofenceEntity(
      id: 1,
      name: '집',
      address: '서울',
      lat: 37.5,
      lng: 127,
      radius: 250,
      message: '도착',
      contactIds: '["7"]',
      isActive: true,
    );

    final contacts = await service.resolveContacts(geofence);

    expect(contacts.single.id, 7);
    expect(service.extractPhoneNumbers(contacts), ['01012345678']);
  });
}

class _Contacts implements ContactLocalRepository {
  @override
  Future<List<ContactEntity>> findAll() async => [
    ContactEntity(id: 7, name: '연락처', number: '010-1234-5678'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Recipients implements GeofenceServerRecipientLocalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
