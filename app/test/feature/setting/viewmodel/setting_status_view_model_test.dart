import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/setting/model/type/setting_status.dart';
import 'package:iamhere/feature/setting/model/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/setting/viewmodel/setting_status_view_model.dart';

class _FakeStatusService implements SettingStatusServiceInterface {
  var granted = <SettingPermission, bool>{
    for (final item in SettingPermission.values) item: false,
  };
  Object? actionError;
  final requested = <SettingPermission>[];
  var openSettingsCalls = 0;
  var loadCalls = 0;

  @override
  Future<SettingStatus> load() async {
    loadCalls++;
    return SettingStatus(
      permissions: Map.of(granted),
      lastDelivery: null,
      appVersion: '1.0.0 (1)',
    );
  }

  @override
  Future<void> requestPermission(SettingPermission permission) async {
    final error = actionError;
    if (error != null) throw error;
    requested.add(permission);
    granted[permission] = true;
  }

  @override
  Future<void> openAppSettings() async {
    final error = actionError;
    if (error != null) throw error;
    openSettingsCalls++;
  }
}

void main() {
  late _FakeStatusService service;
  late ProviderContainer container;

  SettingStatusViewModelProvider provider() =>
      settingStatusViewModelProvider(service);

  setUp(() {
    service = _FakeStatusService();
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('loads the status', () async {
    final status = await container.read(provider().future);

    expect(status.appVersion, '1.0.0 (1)');
    expect(status.isGranted(SettingPermission.notification), isFalse);
  });

  test('requests a missing permission and refreshes the status', () async {
    await container.read(provider().future);

    final outcome = await container
        .read(provider().notifier)
        .onPermissionTap(SettingPermission.notification);

    expect(outcome, PermissionTapOutcome.done);
    expect(service.requested, [SettingPermission.notification]);
    expect(
      container
          .read(provider())
          .value
          ?.isGranted(SettingPermission.notification),
      isTrue,
    );
  });

  test('opens app settings for an already granted permission', () async {
    service.granted[SettingPermission.contacts] = true;
    await container.read(provider().future);

    final outcome = await container
        .read(provider().notifier)
        .onPermissionTap(SettingPermission.contacts);

    expect(outcome, PermissionTapOutcome.done);
    expect(service.openSettingsCalls, 1);
    expect(service.requested, isEmpty);
  });

  test('asks for the location disclosure before doing anything', () async {
    await container.read(provider().future);

    final outcome = await container
        .read(provider().notifier)
        .onPermissionTap(SettingPermission.locationAlways);

    expect(outcome, PermissionTapOutcome.needsLocationDisclosure);
    expect(service.requested, isEmpty);
    expect(service.openSettingsCalls, 0);
  });

  test('reports a failed permission action', () async {
    await container.read(provider().future);
    service.actionError = StateError('boom');

    final outcome = await container
        .read(provider().notifier)
        .onPermissionTap(SettingPermission.notification);

    expect(outcome, PermissionTapOutcome.failed);
  });

  test('refresh picks up permissions changed outside the app', () async {
    await container.read(provider().future);
    service.granted[SettingPermission.notification] = true;
    await container.read(provider().notifier).refresh();
    expect(
      container
          .read(provider())
          .value
          ?.isGranted(SettingPermission.notification),
      isTrue,
    );
  });

  test('openAppSettings reports whether the settings opened', () async {
    await container.read(provider().future);
    final notifier = container.read(provider().notifier);

    expect(await notifier.openAppSettings(), isTrue);

    service.actionError = StateError('boom');
    expect(await notifier.openAppSettings(), isFalse);
  });
}
