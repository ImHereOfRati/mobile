/// Single source of truth for the deployment origin.
///
/// The host used to be written out at each call site — `main.dart` twice,
/// the geofence background isolate, and the web shell resolver. Changing
/// domains meant finding every copy. They all read from here now, and a build
/// can override it with `--dart-define=IMHERE_ORIGIN=https://example.test`.
class AppOrigin {
  const AppOrigin._();

  /// Origin root, no trailing slash. API endpoints are prefixed with `/api`
  /// (see `auth_service.dart`), so callers append their own path.
  static const String origin = String.fromEnvironment(
    'IMHERE_ORIGIN',
    defaultValue: 'https://imhere.ratiko.co.kr',
  );

  /// Build-time fallback for the web shell. Remote Config `web_app_url`
  /// overrides this at runtime; this value is the rollback path when Remote
  /// Config is unreachable, so it must stay valid on its own.
  static const String webAppUrl = String.fromEnvironment(
    'IMHERE_WEB_URL',
    defaultValue: '$origin/app',
  );

  /// Host without scheme or path — for DNS reachability checks.
  static String get host => Uri.parse(origin).host;
}
