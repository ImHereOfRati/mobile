/// Canonical origin used for backend requests and background work.
class AppOrigin {
  const AppOrigin._();

  static const String origin = String.fromEnvironment(
    'IMHERE_ORIGIN',
    defaultValue: 'https://imhere.ratiko.co.kr',
  );
}
