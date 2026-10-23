import 'dart:convert';

import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';

class BridgeRpcException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const BridgeRpcException(this.code, this.message, [this.details]);
}

class BridgeRpcServer {
  final BridgeHandlerRegistry handlers;

  const BridgeRpcServer(this.handlers);

  Future<String> handle(String rawMessage) async {
    String id = 'unknown';
    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map<String, dynamic>) {
        throw const BridgeRpcException(
          'INVALID_REQUEST',
          'Bridge request must be a JSON object.',
        );
      }

      id = decoded['id'] is String ? decoded['id'] as String : 'unknown';
      if (decoded['kind'] != 'request' ||
          decoded['id'] is! String ||
          decoded['method'] is! String) {
        throw const BridgeRpcException(
          'INVALID_REQUEST',
          'Bridge request requires kind, id, and method.',
        );
      }

      final result = await handlers.invoke(
        decoded['method'] as String,
        decoded['params'],
      );
      return jsonEncode(<String, Object?>{
        'kind': 'response',
        'id': id,
        'result': result,
      });
    } on BridgeMethodNotFoundException catch (error) {
      return _error(id, 'METHOD_NOT_FOUND', error.toString());
    } on BridgeRpcException catch (error) {
      return _error(id, error.code, error.message, error.details);
    } catch (error) {
      return _error(id, 'NATIVE_ERROR', error.toString());
    }
  }

  static String event(String event, [Object? payload]) {
    return jsonEncode(<String, Object?>{
      'kind': 'event',
      'event': event,
      if (payload != null) 'payload': payload,
    });
  }

  static String _error(
    String id,
    String code,
    String message, [
    Object? details,
  ]) {
    return jsonEncode(<String, Object?>{
      'kind': 'response',
      'id': id,
      'error': <String, Object?>{
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
    });
  }
}
