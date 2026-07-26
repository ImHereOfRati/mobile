import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/bridge/delegating_bridge_handler_group.dart';

void main() {
  test('correlates successful responses with the request id', () async {
    Object? delegatedParams;
    final server = BridgeRpcServer(
      BridgeHandlerRegistry([
        {
          'queryGeofences': (params) {
            delegatedParams = params;
            return {'items': <Object?>[], 'nextCursor': null};
          },
        },
      ]),
    );

    final response =
        jsonDecode(
              await server.handle(
                jsonEncode({
                  'kind': 'request',
                  'id': 'request-42',
                  'method': 'queryGeofences',
                  'params': {'limit': 20},
                }),
              ),
            )
            as Map<String, dynamic>;

    expect(response['id'], 'request-42');
    expect(response['result'], {'items': <Object?>[], 'nextCursor': null});
    expect(delegatedParams, {'limit': 20});
  });

  test('returns a typed error for an unknown or unwired method', () async {
    final server = BridgeRpcServer(BridgeHandlerRegistry(const []));
    final response =
        jsonDecode(
              await server.handle(
                '{"kind":"request","id":"1","method":"getAuthState"}',
              ),
            )
            as Map<String, dynamic>;

    expect((response['error'] as Map)['code'], 'METHOD_NOT_FOUND');
  });

  test('never exposes refresh tokens through auth responses', () async {
    final registry = BridgeHandlerRegistry([
      {
        'signInWithKakao': (_) => {
          'authState': {'authenticated': true, 'userStatus': 'active'},
          'token': {
            'accessToken': 'access',
            'refreshToken': 'secret',
            'refresh_token': 'also-secret',
          },
        },
      },
    ]);

    final result =
        await registry.invoke('signInWithKakao', null) as Map<String, Object?>;
    final token = result['token'] as Map<String, Object?>;

    expect(token['accessToken'], 'access');
    expect(token, isNot(contains('refreshToken')));
    expect(token, isNot(contains('refresh_token')));
  });

  test('rejects duplicate handler ownership', () {
    expect(
      () => BridgeHandlerRegistry([
        {'signOut': (_) => null},
        {'signOut': (_) => null},
      ]),
      throwsArgumentError,
    );
  });

  test('requires every geofence and device delegate to be wired', () {
    expect(
      () => DelegatingBridgeHandlerGroup.geofenceAndDevice({
        'queryGeofences': (_) => null,
      }),
      throwsArgumentError,
    );
  });
}
