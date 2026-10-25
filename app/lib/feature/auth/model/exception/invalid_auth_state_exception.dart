class InvalidAuthStateException implements Exception {
  const InvalidAuthStateException(this.statusCode);

  final int statusCode;
}
