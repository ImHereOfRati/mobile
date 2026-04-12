import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String message;

  const BlackButton({
    super.key,
    required this.onPressed,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return _buildStartButton();
  }

  SizedBox _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: _startButtonStyle(),
        child: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: 16.h),
        ),
      ),
    );
  }

  ButtonStyle _startButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.h)),
    );
  }
}
