import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';

typedef AuthLogin = Future<String> Function();
typedef AuthVoidAction = Future<void> Function();
typedef TermsActivation =
    Future<void> Function(List<Map<String, Object?>> consents);
typedef TokenRefresh = Future<String?> Function();

class AuthBridgeHandlers {
  final Future<String?> Function() _readAccessToken;
  final Future<String?> Function() _readUserStatus;
  final Future<bool?> Function() _readIsActive;
  final Future<bool> Function() _readPending;
  final TokenRefresh _refresh;
  final AuthLogin _signInWithKakao;
  final AuthLogin _signInWithGoogle;
  final TermsActivation _activateWithTerms;
  final AuthVoidAction _signOut;
  final AuthVoidAction _withdraw;

  AuthBridgeHandlers({
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() readUserStatus,
    required Future<bool?> Function() readIsActive,
    required Future<bool> Function() readPending,
    required TokenRefresh refresh,
    required AuthLogin signInWithKakao,
    required AuthLogin signInWithGoogle,
    required TermsActivation activateWithTerms,
    required AuthVoidAction signOut,
    required AuthVoidAction withdraw,
  }) : _readAccessToken = readAccessToken,
       _readUserStatus = readUserStatus,
       _readIsActive = readIsActive,
       _readPending = readPending,
       _refresh = refresh,
       _signInWithKakao = signInWithKakao,
       _signInWithGoogle = signInWithGoogle,
       _activateWithTerms = activateWithTerms,
       _signOut = signOut,
       _withdraw = withdraw;

  Map<String, BridgeMethodHandler> build() => {
    'getAuthState': (_) => _authState(),
    'getAccessToken': (_) async => _token(await _readAccessToken()),
    'refreshAccessToken': (_) async => _token(await _refresh()),
    'signInWithKakao': (_) => _signIn(_signInWithKakao),
    'signInWithGoogle': (_) => _signIn(_signInWithGoogle),
    'activateWithTerms': _activate,
    'signOut': (_) => _signOut(),
    'withdraw': (_) => _withdraw(),
  };

  Future<Map<String, Object?>> _authState() async {
    final token = await _readAccessToken();
    return {
      'authenticated': token != null && token.isNotEmpty,
      'userStatus': await _userStatus(),
    };
  }

  Future<Map<String, Object?>> _signIn(AuthLogin login) async {
    await login();
    return _session();
  }

  Future<Map<String, Object?>> _activate(Object? params) async {
    if (params is! Map || params['consents'] is! List) {
      throw const FormatException('Expected terms consents.');
    }
    final consents = (params['consents'] as List).map((raw) {
      if (raw is! Map || raw['id'] is! int || raw['agreed'] is! bool) {
        throw const FormatException('Invalid terms consent.');
      }
      return <String, Object?>{
        'id': raw['id'] as int,
        'agreed': raw['agreed'] as bool,
      };
    }).toList();
    await _activateWithTerms(consents);
    return _session();
  }

  Future<Map<String, Object?>> _session() async {
    return {
      'authState': await _authState(),
      'token': _token(await _readAccessToken()),
    };
  }

  Future<String?> _userStatus() async {
    if (await _readPending()) return 'pending';
    final raw = (await _readUserStatus())?.toUpperCase();
    if (raw == 'PENDING') return 'pending';
    if (raw == 'INACTIVE' || await _readIsActive() == false) return 'inactive';
    if (raw == 'ACTIVE' || await _readIsActive() == true) return 'active';
    return null;
  }

  static Map<String, Object?> _token(String? value) => {
    'accessToken': value,
    'expiresAt': null,
  };
}
