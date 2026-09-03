import 'dart:async';

import 'package:iamhere/shell/bridge/generated/bridge_contract.generated.dart';

typedef BridgeMethodHandler = FutureOr<Object?> Function(Object? params);

class BridgeMethodNotFoundException implements Exception {
  final String method;

  const BridgeMethodNotFoundException(this.method);

  @override
  String toString() => 'Bridge method is not registered: $method';
}

class BridgeHandlerRegistry {
  static const _tokenMethods = <String>{
    'getAccessToken',
    'refreshAccessToken',
    'signInWithKakao',
    'signInWithGoogle',
    'activateWithTerms',
  };

  final Map<String, BridgeMethodHandler> _handlers;

  BridgeHandlerRegistry(Iterable<Map<String, BridgeMethodHandler>> groups)
    : _handlers = _merge(groups);

  Set<String> get registeredMethods => Set.unmodifiable(_handlers.keys);

  Set<String> get missingMethods =>
      bridgeMethodNames.toSet().difference(_handlers.keys.toSet());

  bool get isComplete => missingMethods.isEmpty;

  Future<Object?> invoke(String method, Object? params) async {
    final handler = _handlers[method];
    if (handler == null) throw BridgeMethodNotFoundException(method);
    final result = await handler(params);
    return _tokenMethods.contains(method)
        ? _stripRefreshTokens(result)
        : result;
  }

  static Map<String, BridgeMethodHandler> _merge(
    Iterable<Map<String, BridgeMethodHandler>> groups,
  ) {
    final result = <String, BridgeMethodHandler>{};
    for (final group in groups) {
      for (final entry in group.entries) {
        if (!bridgeMethodNames.contains(entry.key)) {
          throw ArgumentError.value(
            entry.key,
            'method',
            'Unknown bridge method',
          );
        }
        if (result.containsKey(entry.key)) {
          throw ArgumentError.value(
            entry.key,
            'method',
            'Duplicate bridge method',
          );
        }
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static Object? _stripRefreshTokens(Object? value) {
    if (value is List<Object?>) {
      return value.map(_stripRefreshTokens).toList(growable: false);
    }
    if (value is Map) {
      return <String, Object?>{
        for (final entry in value.entries)
          if (!_isRefreshTokenKey(entry.key.toString()))
            entry.key.toString(): _stripRefreshTokens(entry.value),
      };
    }
    return value;
  }

  static bool _isRefreshTokenKey(String key) {
    final normalised = key.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    return normalised == 'refreshtoken' || normalised == 'refresh';
  }
}

const authBridgeMethodNames = <String>{
  'getAuthState',
  'getAccessToken',
  'refreshAccessToken',
  'signInWithKakao',
  'signInWithGoogle',
  'activateWithTerms',
  'signOut',
};

const permissionAndAppBridgeMethodNames = <String>{
  'getPermissionStatus',
  'requestPermission',
  'openAppSettings',
  'getAutoSendReadiness',
  'getAppInfo',
  'openExternalUrl',
  'share',
  'haptic',
  'setStatusBarStyle',
  'exitApp',
  'setAnalyticsConsent',
  'logEvent',
};

const geofenceAndDeviceBridgeMethodNames = <String>{
  'registerGeofence',
  'unregisterGeofence',
  'setGeofenceActive',
  'updateGeofenceAddress',
  'syncGeofences',
  'getNativeGeofenceState',
  'queryGeofences',
  'queryRecords',
  'queryNotifications',
  'deleteRecord',
  'deleteAllRecords',
  'deleteAllNotifications',
  'getDeviceContacts',
  'pickDeviceContact',
  'updateDeviceContact',
  'deleteDeviceContact',
  'getCurrentPosition',
  'getLocationServiceStatus',
};
