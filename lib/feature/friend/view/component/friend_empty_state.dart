import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendEmptyState extends StatelessWidget {
  const FriendEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        '등록된 친구가 없습니다.\n위 버튼을 눌러 친구를 추가하세요.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 15.sp,
          color: cs.onSurface.withValues(alpha: 0.45),
          height: 1.5,
        ),
      ),
    );
  }
}
