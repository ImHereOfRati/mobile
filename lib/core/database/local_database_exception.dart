/// Custom exception for database operations
class LocalDatabaseException implements Exception {
  static const DATABASE_EXCEPTION_TITLE = "데이터베이스 오류 발생\n\n";
  static const DATABASE_EXCEPTION_DETAIL = "상세 내용\n";
  static const DATABASE_EXCEPTION_ORIGINAL_ERROR = "ORIGIN ERROR\n";

  final String message;
  final String? details;
  final Object? originalError;

  LocalDatabaseException(this.message, {this.details, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer(DATABASE_EXCEPTION_ORIGINAL_ERROR);
    buffer.write('$message\n\n');
    if (details != null) {
      buffer.write(DATABASE_EXCEPTION_DETAIL);
      buffer.write(details);
      buffer.write('\n\n');
    }
    if (originalError != null) {
      buffer.write(DATABASE_EXCEPTION_ORIGINAL_ERROR);
      buffer.write(originalError);
      buffer.write('\n\n');
    }
    return buffer.toString();
  }
}
