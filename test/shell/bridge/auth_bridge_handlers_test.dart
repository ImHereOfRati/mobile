import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/bridge/auth_bridge_handlers.dart';

void main() {
  test(
    'returns the persisted active auth session without a refresh token',
    () async {
      var accessToken = 'access-1';
      final handlers = AuthBridgeHandlers(
        readAccessToken: () async => accessToken,
        readUserStatus: () async => 'ACTIVE',
        readIsActive: () async => true,
        readPending: () async => false,
        refresh: () async => accessToken = 'access-2',
        signInWithKakao: () async => 'active',
        signInWithGoogle: () async => 'active',
        activateWithTerms: (_) async {},
        signOut: () async => accessToken = '',
        withdraw: () async => accessToken = '',
      ).build();

      expect(await handlers['getAuthState']!(null), {
        'authenticated': true,
        'userStatus': 'active',
      });
      expect(await handlers['refreshAccessToken']!(null), {
        'accessToken': 'access-2',
        'expiresAt': null,
      });
    },
  );

  test('maps a pending login to the stored auth snapshot', () async {
    String? token;
    var pending = false;
    final handlers = AuthBridgeHandlers(
      readAccessToken: () async => token,
      readUserStatus: () async => pending ? 'PENDING' : null,
      readIsActive: () async => null,
      readPending: () async => pending,
      refresh: () async => token,
      signInWithKakao: () async {
        token = 'access';
        pending = true;
        return 'pending';
      },
      signInWithGoogle: () async => 'active',
      activateWithTerms: (_) async {},
      signOut: () async {},
      withdraw: () async {},
    ).build();

    expect(await handlers['signInWithKakao']!(null), {
      'authState': {'authenticated': true, 'userStatus': 'pending'},
      'token': {'accessToken': 'access', 'expiresAt': null},
    });
  });

  test('activates terms natively and returns only the access token', () async {
    var token = 'pending-access';
    var status = 'PENDING';
    List<Map<String, Object?>>? received;
    final handlers = AuthBridgeHandlers(
      readAccessToken: () async => token,
      readUserStatus: () async => status,
      readIsActive: () async => status == 'ACTIVE',
      readPending: () async => status == 'PENDING',
      refresh: () async => token,
      signInWithKakao: () async => 'pending',
      signInWithGoogle: () async => 'pending',
      activateWithTerms: (consents) async {
        received = consents;
        token = 'active-access';
        status = 'ACTIVE';
      },
      signOut: () async {},
      withdraw: () async {},
    ).build();

    expect(
      await handlers['activateWithTerms']!({
        'consents': [
          {'id': 1, 'agreed': true},
          {'id': 2, 'agreed': false},
        ],
      }),
      {
        'authState': {'authenticated': true, 'userStatus': 'active'},
        'token': {'accessToken': 'active-access', 'expiresAt': null},
      },
    );
    expect(received, [
      {'id': 1, 'agreed': true},
      {'id': 2, 'agreed': false},
    ]);
  });
}
