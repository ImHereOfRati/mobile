import 'package:flutter/material.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/service/account/auth_fcm_registration_service.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/friend/model/repository/contact_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_local_repository.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_local_repository.dart';
import 'package:iamhere/feature/record/model/repository/notification_local_repository.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/network/instance/token_refresher.dart';
import 'package:iamhere/shell/bridge/auth_bridge_handlers.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/bridge/device_contact_reader.dart';
import 'package:iamhere/shell/bridge/device_contact_sync_service.dart';
import 'package:iamhere/shell/bridge/flutter_app_bridge_handlers.dart';
import 'package:iamhere/shell/bridge/geofence_device_bridge_handlers.dart';
import 'package:iamhere/shell/bridge/permission_bridge_handlers.dart';

class ShellBridgeFactory {
  const ShellBridgeFactory._();

  static BridgeRpcServer create({
    required ValueNotifier<ThemeMode> themeMode,
    required Future<void> Function(ThemeMode) saveTheme,
  }) {
    final tokenStorage = getIt<TokenStorageService>();
    final authCoordinator = getIt<SocialLoginService>();
    final authFcmRegistrationService = getIt<AuthFcmRegistrationService>();
    final auth = AuthBridgeHandlers(
      readAccessToken: tokenStorage.getAccessToken,
      readUserStatus: tokenStorage.getUserStatus,
      readIsActive: tokenStorage.getIsActive,
      readPending: tokenStorage.getPendingAuth,
      refresh: () async {
        final response = await getIt<TokenRefresher>().refresh();
        if (response.data == null) throw StateError(response.message);
        return response.data;
      },
      signInWithKakao: () => _loginAndSyncFcm(
        authFcmRegistrationService,
        authCoordinator.handleKakaoLogin,
      ),
      signInWithGoogle: () => _loginAndSyncFcm(
        authFcmRegistrationService,
        authCoordinator.handleGoogleLogin,
      ),
      activateWithTerms: getIt<AuthService>().activateWithTerms,
    );
    final permissions = PermissionBridgeHandlers(
      location: getIt<PermissionServiceInterface>(instanceName: 'location'),
      notification: getIt<PermissionServiceInterface>(instanceName: 'fcmAlert'),
      batteryOptimization: getIt<PermissionServiceInterface>(
        instanceName: 'batteryOptimization',
      ),
      contacts: getIt<PermissionServiceInterface>(instanceName: 'friend'),
    );
    final deviceContacts = DeviceContactSyncService(
      const DeviceContactReader(),
      getIt<ContactLocalRepository>(),
    );
    final geofenceAndDevice = GeofenceDeviceBridgeHandlers(
      geofences: getIt<GeofenceLocalRepository>(),
      contacts: getIt<ContactLocalRepository>(),
      recipients: getIt<GeofenceServerRecipientLocalRepository>(),
      records: getIt<GeofenceRecordLocalRepository>(),
      notifications: getIt<NotificationLocalRepository>(),
      loadDeviceContacts: deviceContacts.load,
      loadDeviceContactPicker: deviceContacts.pick,
      notifyServerRecipients:
          ({required receiverUserIds, required location}) async {
            await getIt<FcmArrivalService>().sendGeofenceNotifications(
              receiverUserIds: receiverUserIds,
              body: '위치 알림 대상자로 등록되었습니다.',
              location: location,
              type: 'LOCATION_TARGET',
            );
          },
      registrar: getIt<NativeGeofenceRegistrarInterface>(),
      location: LocatePermissionService(),
    );
    final registry = BridgeHandlerRegistry([
      FlutterAppBridgeHandlers(
        themeMode: themeMode,
        saveTheme: saveTheme,
      ).build(),
      auth.build(),
      permissions.build(),
      geofenceAndDevice.build(),
    ]);
    if (!registry.isComplete) {
      throw StateError(
        'Incomplete native bridge: ${registry.missingMethods.join(', ')}',
      );
    }
    return BridgeRpcServer(registry);
  }

  static Future<String> _loginAndSyncFcm(
    AuthFcmRegistrationService authFcmRegistrationService,
    Future<Result<MemberState>> Function() authenticate,
  ) async {
    final result = await authenticate();
    final state = result.when(
      success: (value) => value,
      failure: (message) => throw StateError(message),
    );
    if (state == MemberState.existingUser) {
      await authFcmRegistrationService.requestAndEnroll();
    } else {
      AppLogger.debug(
        'AuthBridge: pending/new user -> skip active-only FCM enrollment',
      );
    }
    return state == MemberState.existingUser ? 'active' : 'pending';
  }
}
