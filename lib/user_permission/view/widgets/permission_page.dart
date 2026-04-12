import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/view_component/widgets/black_button.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';

import '../../model/permission_item.dart';

/// 개별 권한 요청 페이지 위젯
class PermissionPage extends ConsumerWidget {
  final int pageIndex;
  final PermissionItem item;
  final VoidCallback onNext;

  const PermissionPage({
    super.key,
    required this.pageIndex,
    required this.item,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [라벨] 내용 형식을 파싱
    final List<String> lines = item.detailedDesc.split('\n');
    final List<Widget> descriptionWidgets = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        descriptionWidgets.add(SizedBox(height: 12.h));
        continue;
      }

      final labelMatch = RegExp(r'^\[(.*?)\]\s*(.*)').firstMatch(line);
      if (labelMatch != null) {
        // [라벨] 형식인 경우
        descriptionWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80.w,
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(
                    labelMatch.group(1)!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    labelMatch.group(2)!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // 일반 문구인 경우
        descriptionWidgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24.h),
          _buildHeader(),
          SizedBox(height: 32.h),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: descriptionWidgets,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          _buildButtons(context, ref),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 32.w, color: Colors.black87),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (item.isRequired)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    '필수 권한',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    const laterText = '나중에';
    const skipText = '건너뛰기 (권장하지 않음)';

    return Column(
      children: [
        _buildAllowButton(ref),
        SizedBox(height: 16.h),
        if (!item.isRequired)
          _buildTextButton(label: laterText, onPressed: onNext)
        else
          _buildTextButton(
            label: skipText,
            isWarning: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("원활한 서비스 이용을 위해 필수 권한입니다."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTextButton({
    required String label,
    required VoidCallback onPressed,
    bool isWarning = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isWarning ? Colors.grey[600] : Colors.grey[500],
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14.sp, decoration: TextDecoration.underline),
      ),
    );
  }

  Widget _buildAllowButton(WidgetRef ref) {
    final vm = ref.read(userPermissionViewModelProvider.notifier);
    const allowText = '허용하기';

    return BlackButton(
      onPressed: () async {
        await vm.requestPermission(pageIndex - 1);
        onNext();
      },
      message: allowText,
    );
  }
}
