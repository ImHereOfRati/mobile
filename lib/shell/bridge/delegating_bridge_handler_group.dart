import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';

class DelegatingBridgeHandlerGroup {
  final Map<String, BridgeMethodHandler> handlers;

  DelegatingBridgeHandlerGroup.auth(Map<String, BridgeMethodHandler> delegates)
    : handlers = _validate('auth', authBridgeMethodNames, delegates);

  DelegatingBridgeHandlerGroup.permissionAndApp(
    Map<String, BridgeMethodHandler> delegates,
  ) : handlers = _validate(
        'permissionAndApp',
        permissionAndAppBridgeMethodNames,
        delegates,
      );

  DelegatingBridgeHandlerGroup.geofenceAndDevice(
    Map<String, BridgeMethodHandler> delegates,
  ) : handlers = _validate(
        'geofenceAndDevice',
        geofenceAndDeviceBridgeMethodNames,
        delegates,
      );

  static Map<String, BridgeMethodHandler> _validate(
    String group,
    Set<String> expected,
    Map<String, BridgeMethodHandler> delegates,
  ) {
    final actual = delegates.keys.toSet();
    final missing = expected.difference(actual);
    final extra = actual.difference(expected);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw ArgumentError(
        '$group bridge delegates mismatch '
        '(missing: ${missing.join(', ')}, extra: ${extra.join(', ')}).',
      );
    }
    return Map.unmodifiable(delegates);
  }
}
