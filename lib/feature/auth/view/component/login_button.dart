import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'login_button_info.dart';

class LoginButton extends StatelessWidget {
  final LoginButtonInfo buttonInfo;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.buttonInfo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: Material(
        color: buttonInfo.backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        child: _consistButtonWithContents(),
      ),
    );
  }

  InkWell _consistButtonWithContents() {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      splashColor: Colors.black.withValues(alpha: 0.06),
      highlightColor: Colors.black.withValues(alpha: 0.04),
      child: _consistButtonContents(),
    );
  }

  Row _consistButtonContents() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          buttonInfo.assetAddress,
          width: 22.r,
          height: 22.r,
          fit: BoxFit.contain,
        ),
        Padding(padding: EdgeInsets.all(8.0)),
        Text(
          buttonInfo.description,
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF191919),
            letterSpacing: -0.3,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
