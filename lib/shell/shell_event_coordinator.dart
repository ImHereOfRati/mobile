import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/shell/bridge/bridge_event_emitter.dart';

class ShellEventCoordinator {
  final BridgeEventEmitter emitter;

  const ShellEventCoordinator(this.emitter);

  Future<void> appResumed() => emitter.emit('onAppResumed');

  Future<void> permissionChanged(String permission, String status) {
    return emitter.emit('onPermissionChanged', <String, Object?>{
      'permission': permission,
      'status': status,
    });
  }

  Future<void> connectivityChanged({
    required bool connected,
    required String connectionType,
  }) {
    return emitter.emit('onConnectivityChanged', <String, Object?>{
      'connected': connected,
      'connectionType': connectionType,
    });
  }

  Future<bool> pushOpened(Map<String, dynamic> data) async {
    final path = extractNotificationPath(data);
    if (path == null) return false;
    await emitter.emit('onPushOpened', <String, Object?>{'path': path});
    return true;
  }

  Future<void> themeChanged(String theme) {
    return emitter.emit('onThemeChanged', <String, Object?>{'theme': theme});
  }

  Future<void> androidBackPressed() {
    return emitter.emit('onAndroidBackPressed');
  }
}
