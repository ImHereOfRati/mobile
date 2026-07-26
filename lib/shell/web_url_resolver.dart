import 'package:iamhere/integration/firebase/firebase_remote_service.dart';

typedef RemoteWebUrlLoader = Future<String?> Function();

class WebUrlResolver {
  static const String buildFallbackUrl = String.fromEnvironment(
    'IMHERE_WEB_URL',
    defaultValue: 'https://fortuneki.site/app',
  );

  final RemoteWebUrlLoader _loadRemoteUrl;
  final Uri fallbackUrl;

  WebUrlResolver({required RemoteWebUrlLoader loadRemoteUrl, Uri? fallbackUrl})
    : _loadRemoteUrl = loadRemoteUrl,
      fallbackUrl = fallbackUrl ?? Uri.parse(buildFallbackUrl);

  factory WebUrlResolver.firebase(FirebaseRemoteService remoteService) {
    return WebUrlResolver(
      loadRemoteUrl: () async => remoteService.webAppUrlOrNull,
    );
  }

  Future<Uri> resolve() async {
    try {
      final candidate = _parse(_normalise(await _loadRemoteUrl()));
      if (candidate != null) return candidate;
    } catch (_) {
      // Remote Config is a rollout switch. A fetch/read failure must always
      // preserve the build-time rollback URL.
    }
    return fallbackUrl;
  }

  static Uri? _parse(String? raw) {
    if (raw == null) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'https') return null;
    return uri;
  }

  static String? _normalise(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
