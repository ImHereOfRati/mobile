import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';

class FcmAlertPermissionService implements PermissionServiceInterface {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  Future<PermissionState> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
    return _mapAuthStatusToPermissionState(settings.authorizationStatus);
  }

  @override
  Future<PermissionState> checkPermissionStatus() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    return _mapAuthStatusToPermissionState(settings.authorizationStatus);
  }

  @override
  Future<bool> isPermissionGranted() async {
    final status = await checkPermissionStatus();
    return status == PermissionState.grantedAlways ||
        status == PermissionState.grantedWhenInUse;
  }

  /// Firebase AuthorizationStatus를 PermissionState로 매핑
  PermissionState _mapAuthStatusToPermissionState(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PermissionState.grantedAlways;
      case AuthorizationStatus.denied:
        return PermissionState.denied;
      case AuthorizationStatus.notDetermined:
        return PermissionState.denied;
    }
  }
}
