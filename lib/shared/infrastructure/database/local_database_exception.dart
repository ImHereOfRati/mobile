/// Custom exception for database operations
class LocalDatabaseException implements Exception {
  final String message;
  final String? details;
  final Object? originalError;

  LocalDatabaseException(this.message, {this.details, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer('DatabaseException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}
