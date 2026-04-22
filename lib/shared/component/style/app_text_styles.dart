import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  static const hannaAir = 'BMHANNAAir';
  static const gSans = 'GmarketSans';

  static TextStyle get _titleBase => TextStyle(
    fontFamily: gSans,
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle get _descriptionBase =>
      TextStyle(fontFamily: hannaAir, fontSize: 13.sp, letterSpacing: -0.2);

  static TextStyle bigBlackTitle(ColorScheme colorScheme) =>
      _titleBase.copyWith(color: colorScheme.onSurface, height: 1.14);

  static TextStyle smallGreyDescription(ColorScheme colorScheme) =>
      _descriptionBase.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.55),
        height: 1.43,
      );

  static TextStyle smallBlueDescription(ColorScheme colorScheme) =>
      _descriptionBase.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      );

  //유일하게 색깔을 parameter로 받는다.
  static TextStyle tooSmallReactiveColorDescription(Color color) {
    return _descriptionBase.copyWith(
      fontSize: 10.sp,
      color: color,
      letterSpacing: -0.1,
    );
  }
}
