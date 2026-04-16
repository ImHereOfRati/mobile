import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/view/component/device_tile.dart';
import 'package:iamhere/shared/util/date_time_formatter.dart';

import 'target_tile.dart';

class RecordTile extends StatelessWidget {
  final Key? tileKey; // 사용자 지정 키
  final String locationName; // "회사"
  final DateTime recordTime; // 2025-11-06 09:15
  final String message; // "회사에 도착했습니다!"
  final String targetName; // "팀장님"
  final SendMachine sendMachine; // 전송한 기기

  const RecordTile({
    this.tileKey,
    required this.locationName,
    required this.recordTime,
    required this.message,
    required this.targetName,
    required this.sendMachine,
  }) : super(key: tileKey);

  @override
  Widget build(BuildContext context) {
    const Color mainColor = Color(0xFF66C8C8);
    final tileBackgroundColor = Theme.of(context).colorScheme.surface;

    /**
     * 구성
     * - buildTop : 위치 이름 + 확인 아이콘
     * - buildTImeStamp : 시간 정보
     * - buildMessageTile : 메시지 내용
     * - buildBottom : 타킷 + 기기 정보
     */
    return Card(
      color: tileBackgroundColor,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTop(mainColor, context),
            SizedBox(height: 8.h),
            buildTimeStamp(context),
            SizedBox(height: 6.h),
            buildMessageTile(context),
            Divider(
              thickness: 1,
              color: Colors.grey.withValues(alpha: 0.3),
              height: 10.h,
            ),
            buildBottom(),
          ],
        ),
      ),
    );
  }

  Row buildTop(Color mainColor, BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: mainColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              locationName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
                fontSize: 20.sp,
              ),
            ),
          ],
        ),
        Icon(Icons.check_circle, color: mainColor, size: 24.sp),
      ],
    );
  }

  Row buildTimeStamp(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    TextStyle style = TextStyle(
      fontSize: 14.sp,
      color: onSurface.withValues(alpha: 0.75),
    );
    return Row(
      children: [
        Text("보낸 시각 : ", style: style),
        Text(formatDateTime(recordTime), style: style),
      ],
    );
  }

  Text buildMessageTile(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
    );
  }

  Row buildBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TargetTile(receiver: targetName),
        DeviceTile(sendMachine: sendMachine),
      ],
    );
  }
}
