import 'package:sqflite/sqflite.dart';

import '../../../shared/base/result/error_analyst.dart';
import '../local_database_exception.dart';

/// DB 호출의 공통 에러 변환 경로.
///
/// 모든 SQL 작업은 [safeDbCall] 로 감싸 [LocalDatabaseException] 으로
/// 통일된다. 도메인 코드는 단일 예외 타입만 알면 되고, view 는 [LocalDatabaseException.toString]
/// 으로 사용자에게 의미 있는 메시지를 보여줄 수 있다.
mixin DatabaseHandler {
  Future<T> safeDbCall<T>(
    Future<T> Function() call, {
    required String operation,
    String? details,
  }) async {
    try {
      return await call();
    } on LocalDatabaseException {
      rethrow;
    } on DatabaseException catch (e, stack) {
      ErrorAnalyst.log('DB Error ($operation): $e', stack);
      throw LocalDatabaseException(
        operation,
        details: details,
        originalError: e,
      );
    }
  }
}
