import 'package:dio/dio.dart';
import 'package:iamhere/shared/base/result/result_message.dart';

import '../../../shared/base/result/error_analyst.dart';

mixin DioHandler {
  Future<T> safeApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e, stack) {
      ErrorAnalyst.log(ResultMessage.dioException.toString(), stack);
      throw Exception(ResultMessage.dioException);
    } catch (e, stack) {
      ErrorAnalyst.log("DIO Error: ${e.toString()}", stack);
      rethrow;
    }
  }
}
