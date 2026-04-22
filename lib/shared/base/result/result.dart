import 'package:flutter/material.dart';

import '../snack_bar/app_snack_bar.dart';
import 'error_analyst.dart';

sealed class Result<T> {
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      Success(data: var d) => success(d),
      Failure(message: var m) => failure(m),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final StackTrace? trace;
  Failure(this.message, {this.trace});
}

extension ResultHandler<T> on Result<T> {
  /// 결과를 처리합니다.
  ///
  /// - [onSuccess] : 성공 시 호출됩니다.
  /// - [onFailure] : 실패 시 커스텀 처리가 필요한 경우 제공합니다.
  ///   제공하지 않으면 기본 에러 SnackBar가 표시됩니다.
  /// - [successMessage] : 성공 시 표시할 SnackBar 메시지.
  ///   null 이면 성공 SnackBar를 표시하지 않습니다.
  /// - [showSnackBar] : false 로 설정하면 성공/실패 모두 SnackBar를 표시하지 않습니다.
  void handle({
    required BuildContext context,
    required void Function(T data) onSuccess,
    void Function(String message)? onFailure,
    String? successMessage,
    bool showSnackBar = true,
  }) {
    switch (this) {
      case Success(data: var d):
        onSuccess(d);
        if (showSnackBar && successMessage != null && context.mounted) {
          AppSnackBar.showSuccess(context, successMessage);
        }

      case Failure(message: var msg, trace: var stack):
        ErrorAnalyst.log(msg, stack);
        if (onFailure != null) {
          onFailure(msg);
        } else if (showSnackBar && context.mounted) {
          AppSnackBar.showError(context, msg);
        }
    }
  }
}
