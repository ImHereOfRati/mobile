import 'package:flutter/material.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';

import 'error_analyst.dart';
import 'result.dart';

extension ResultFeedbackHandler<T> on Result<T> {
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
