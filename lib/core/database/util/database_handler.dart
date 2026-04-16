import 'package:sqflite/sqflite.dart';

import '../../../shared/base/result/error_analyst.dart';

mixin DatabaseHandler {
  Future<T> safeDbCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DatabaseException catch (e, stack) {
      ErrorAnalyst.log("DB Error: ${e.toString()}", stack);
      throw Exception("데이터베이스 작업 중 오류가 발생했습니다.");
    } catch (e, stack) {
      rethrow;
    }
  }
}
