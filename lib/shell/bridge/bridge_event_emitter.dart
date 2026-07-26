import 'dart:convert';

import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/bridge/generated/bridge_contract.generated.dart';

typedef JavaScriptRunner = Future<void> Function(String script);

class BridgeEventEmitter {
  final JavaScriptRunner _runJavaScript;

  const BridgeEventEmitter(this._runJavaScript);

  Future<void> emit(String event, [Object? payload]) {
    if (!bridgeEventNames.contains(event)) {
      throw ArgumentError.value(event, 'event', 'Unknown bridge event');
    }
    return sendMessage(BridgeRpcServer.event(event, payload));
  }

  Future<void> sendMessage(String message) {
    final encoded = jsonEncode(message);
    return _runJavaScript(
      'window.__imhereBridgeReceive && '
      'window.__imhereBridgeReceive($encoded);',
    );
  }
}
