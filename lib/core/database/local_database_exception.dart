/// Custom exception for database operations
class LocalDatabaseException implements Exception {
  static const databaseExceptionTitle = "데이터베이스 오류 발생\n\n";
  static const databaseExceptionDetail = "상세 내용\n";
  static const databaseExceptionOriginalError = "ORIGIN ERROR\n";

  final String message;
  final String? details;
  final Object? originalError;

  LocalDatabaseException(this.message, {this.details, this.originalError});

  @override
  String toString() {
    final buffer = StringBuffer(databaseExceptionOriginalError);
    buffer.write('$message\n\n');
    if (details != null) {
      buffer.write(databaseExceptionDetail);
      buffer.write(details);
      buffer.write('\n\n');
    }
    if (originalError != null) {
      buffer.write(databaseExceptionOriginalError);
      buffer.write(originalError);
      buffer.write('\n\n');
    }
    return buffer.toString();
  }
}
