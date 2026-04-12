import 'package:flutter/material.dart';

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
  void handle({
    required BuildContext context,
    required Function(T data) onSuccess,
    bool showSnackBar = true,
  }) {
    switch (this) {
      case Success(data: var d):
        onSuccess(d);

      case Failure(message: var msg, trace: var stack):
        ErrorAnalyst.log(msg, stack);

        if (showSnackBar && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
    }
  }
}
