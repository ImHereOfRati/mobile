import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/user_permission/model/permission_item.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 48.h),
          _buildHeader(),
          SizedBox(height: 28.h),
          Expanded(child: _buildDescription()),
          _buildButtons(context, ref),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(item.icon, size: 28.r, color: const Color(0xFF0071E3)),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Text(
              item.title,
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
                height: 1.14,
              ),
            ),
            if (item.isRequired) ...[
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071E3).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(980.r),
                ),
                child: Text(
                  '필수',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: const Color(0xFF0071E3),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final lines = item.detailedDesc.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 10.h));
        continue;
      }
      final labelMatch = RegExp(r'^\[(.*?)\]\s*(.*)').firstMatch(line);
      if (labelMatch != null) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72.w,
                  child: Text(
                    labelMatch.group(1)!,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    labelMatch.group(2)!,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 14.sp,
                      color: const Color(0xFF6E6E73),
                      letterSpacing: -0.224,
                      height: 1.47,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                color: const Color(0xFF6E6E73),
                letterSpacing: -0.3,
                height: 1.6,
              ),
            ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget _buildButtons(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50.h,
          child: ElevatedButton(
            onPressed: () async {
              await ref
                  .read(userPermissionViewModelProvider.notifier)
                  .requestPermission(pageIndex - 1);
              onNext();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071E3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '허용하기',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.374,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: TextButton(
            onPressed: item.isRequired
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('원활한 서비스 이용을 위해 필수 권한입니다.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    )
                : onNext,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6E6E73),
            ),
            child: Text(
              item.isRequired ? '건너뛰기 (권장하지 않음)' : '나중에',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                letterSpacing: -0.224,
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF6E6E73),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
