import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'native_geofence_registrar_test.mocks.dart';

@GenerateMocks([PermissionServiceInterface])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NativeGeofenceRegistrar registrar;
  late MockPermissionServiceInterface mockPermission;

  late GeofenceEntity activeGeofence;
  late GeofenceEntity inactiveGeofence;
  late GeofenceEntity nullIdGeofence;

  setUp(() {
    mockPermission = MockPermissionServiceInterface();
    registrar = NativeGeofenceRegistrar(mockPermission);

    activeGeofence = GeofenceEntity(
      id: 1,
      name: 'home',
      address: 'addr',
      lat: 37.0,
      lng: 127.0,
      radius: 100,
      message: 'arrived',
      contactIds: '[]',
      isActive: true,
    );
    inactiveGeofence = activeGeofence.copyWith(isActive: false);
    nullIdGeofence = GeofenceEntity(
      id: null,
      name: 'no-id',
      address: '',
      lat: 0,
      lng: 0,
      radius: 100,
      message: 'm',
      contactIds: '[]',
      isActive: true,
    );
  });

  group('register: permission gate', () {
    test('inactive geofence: returns early without checking permission',
        () async {
      await registrar.register(inactiveGeofence);
      verifyZeroInteractions(mockPermission);
    });

    test('null id: returns early without checking permission', () async {
      await registrar.register(nullIdGeofence);
      verifyZeroInteractions(mockPermission);
    });

    test('grantedWhenInUse: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.grantedWhenInUse);

      await expectLater(
        registrar.register(activeGeofence),
        throwsA(
          isA<MissingBackgroundLocationException>().having(
            (e) => e.state,
            'state',
            PermissionState.grantedWhenInUse,
          ),
        ),
      );
    });

    test('denied: throws MissingBackgroundLocationException', () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.denied);

      await expectLater(
        registrar.register(activeGeofence),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });

    test('permanentlyDenied: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.permanentlyDenied);

      await expectLater(
        registrar.register(activeGeofence),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });

    test('serviceDisabled: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.serviceDisabled);

      await expectLater(
        registrar.register(activeGeofence),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });

    test('restricted: throws MissingBackgroundLocationException', () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.restricted);

      await expectLater(
        registrar.register(activeGeofence),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });
  });

  group('syncAll: permission gate', () {
    test('empty active list: skips permission check', () async {
      // syncAll(empty) is a no-op for registration; permission shouldn't be touched.
      try {
        await registrar.syncAll(const []);
      } catch (_) {
        // Plugin platform calls fail in unit tests; ignore.
      }
      verifyZeroInteractions(mockPermission);
    });

    test('all-inactive list: skips permission check', () async {
      try {
        await registrar.syncAll([inactiveGeofence]);
      } catch (_) {}
      verifyZeroInteractions(mockPermission);
    });

    test('active list + grantedWhenInUse: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.grantedWhenInUse);

      await expectLater(
        registrar.syncAll([activeGeofence]),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });

    test('active list + denied: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.denied);

      await expectLater(
        registrar.syncAll([activeGeofence]),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });

    test('active list + serviceDisabled: throws MissingBackgroundLocationException',
        () async {
      when(mockPermission.checkPermissionStatus())
          .thenAnswer((_) async => PermissionState.serviceDisabled);

      await expectLater(
        registrar.syncAll([activeGeofence]),
        throwsA(isA<MissingBackgroundLocationException>()),
      );
    });
  });
}
