import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/view_component/widgets/black_button.dart';

/// 권한 설정 완료 페이지 위젯
class FinishPage extends StatelessWidget {
  final VoidCallback onFinish;

  const FinishPage({super.key, required this.onFinish});

  final _finishTitle = '모든 준비가 완료되었어요!';
  final _finishDescription = '이제 ImHere의 모든 기능을\n자유롭게 이용해보세요.';
  final _buttonMessage = 'ImHere 시작하기';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            Icons.check_circle_rounded,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(height: 32.h),
          Text(
            _finishTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26.h, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Text(
            _finishDescription,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.h, color: Colors.grey, height: 1.5),
          ),
          const Spacer(),
          BlackButton(onPressed: onFinish, message: _buttonMessage),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
