import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FinishPage extends StatelessWidget {
  final VoidCallback onFinish;
  const FinishPage({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          _buildContent(),
          const Spacer(flex: 3),
          _buildButton(),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: const Color(0xFF0071E3),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.check_rounded, size: 30.r, color: Colors.white),
        ),
        SizedBox(height: 20.h),
        Text(
          '모든 준비가\n완료되었어요!',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 34.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.4,
            height: 1.10,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          '이제 ImHere의 모든 기능을\n자유롭게 이용해보세요.',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 17.sp,
            color: const Color(0xFF6E6E73),
            letterSpacing: -0.374,
            height: 1.47,
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        onPressed: onFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D1D1F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          'ImHere 시작하기',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.374,
          ),
        ),
      ),
    );
  }
}
