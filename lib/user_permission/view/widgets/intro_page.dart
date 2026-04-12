import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/view_component/widgets/black_button.dart';

class IntroPage extends StatelessWidget {
  final VoidCallback onNext;

  const IntroPage({super.key, required this.onNext});

  final _appLogoPosition = 'assets/images/app_logo.png';
  final _introTitle = '만나서 반가워요!';
  final _startButtonText = '시작하기';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 40.h),
          Center(child: Image.asset(_appLogoPosition, width: 100.w)),
          SizedBox(height: 24.h),
          Text(
            _introTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 40.h),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ImHere의 원활한 동작을 위해\n몇 가지 권한 설정이 필요합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          BlackButton(onPressed: onNext, message: _startButtonText),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ImHere가 수집하는 데이터',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoItem('위치 정보', '백그라운드 위치 포함'),
          _buildInfoItem('연락처 정보', '기기 내에만 저장'),
          _buildInfoItem('SMS 발송 권한', '자동 문자 발송용'),
          _buildInfoItem('알림 권한', '선택 사항'),
          SizedBox(height: 16.h),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 12.h),
          Text(
            '모든 데이터는 위치 기반 문자 자동 발송 기능을 위해서만 사용되며, 서버로 전송되지 않습니다.',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String subTitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '($subTitle)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
