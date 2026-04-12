import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback onNext;
  const IntroPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 48.h),
          _buildHero(context),
          SizedBox(height: 36.h),
          _buildInfoCard(context),
          const Spacer(),
          _buildStartButton(context),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
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
          child: Icon(Icons.location_on, size: 30.r, color: Colors.white),
        ),
        SizedBox(height: 20.h),
        Text(
          '만나서 반가워요!',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 34.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.4,
            height: 1.10,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'ImHere의 원활한 동작을 위해\n몇 가지 권한 설정이 필요합니다.',
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

  Widget _buildInfoCard(BuildContext context) {
    final items = [
      ('위치 정보', '백그라운드 위치 포함', Icons.location_on_outlined),
      ('연락처 정보', '기기 내에만 저장', Icons.people_outline),
      ('SMS 발송 권한', '자동 문자 발송용', Icons.sms_outlined),
      ('알림 권한', '선택 사항', Icons.notifications_outlined),
    ];

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ImHere가 수집하는 데이터',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: const Color(0xFF6E6E73),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 14.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Icon(item.$3, size: 18.r, color: const Color(0xFF0071E3)),
                  SizedBox(width: 10.w),
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 13.sp,
                      color: const Color(0xFF6E6E73),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 0.5, color: const Color(0xFFD2D2D7)),
          SizedBox(height: 12.h),
          Text(
            '모든 데이터는 위치 기반 문자 자동 발송 기능을 위해서만 사용되며, 서버로 전송되지 않습니다.',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: const Color(0xFF6E6E73),
              letterSpacing: -0.12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1D1D1F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          '시작하기',
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
