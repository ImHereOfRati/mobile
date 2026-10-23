class InvalidAuthSessionException implements Exception {
  const InvalidAuthSessionException(this.statusCode);

  final int statusCode;
}
