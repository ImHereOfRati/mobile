import 'package:flutter/material.dart';

@immutable
class AppFeedbackColors extends ThemeExtension<AppFeedbackColors> {
  final Color success;

  const AppFeedbackColors({required this.success});

  @override
  AppFeedbackColors copyWith({Color? success}) {
    return AppFeedbackColors(
      success: success ?? this.success,
    );
  }

  @override
  AppFeedbackColors lerp(
    covariant ThemeExtension<AppFeedbackColors>? other,
    double t,
  ) {
    if (other is! AppFeedbackColors) return this;
    return AppFeedbackColors(
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}
