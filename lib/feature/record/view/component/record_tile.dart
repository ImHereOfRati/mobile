import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

class RecordTile extends StatelessWidget {
  final String locationName;
  final DateTime recordTime;
  final String message;
  final String targetName;
  final SendMachine sendMachine;

  const RecordTile({
    super.key,
    required this.locationName,
    required this.recordTime,
    required this.message,
    required this.targetName,
    required this.sendMachine,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더: 위치 + 성공 뱃지 ───────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: cs.primary,
                  size: 20.r,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    locationName,
                    style: tt.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(980.r),
                  ),
                  child: Text(
                    '전송 완료',
                    style: tt.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // ── 메시지 ───────────────────────────────────────────────
            Text(message, style: tt.bodyLarge),

            SizedBox(height: 12.h),

            // ── 구분선 ───────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 0.5,
              color: cs.onSurface.withValues(alpha: 0.08),
            ),

            SizedBox(height: 12.h),

            // ── 하단 메타 정보 ───────────────────────────────────────
            Row(
              children: [
                // 수신자
                Icon(
                  Icons.person_outline_rounded,
                  size: 14.r,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                SizedBox(width: 4.w),
                Text(targetName, style: tt.bodyMedium),

                SizedBox(width: 12.w),

                // 전송 기기
                Icon(
                  sendMachine == SendMachine.mobile
                      ? Icons.phone_iphone_rounded
                      : Icons.cloud_outlined,
                  size: 14.r,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                SizedBox(width: 4.w),
                Text(sendMachine.description, style: tt.bodyMedium),

                const Spacer(),

                // 시간
                Text(
                  _formatRelativeTime(recordTime),
                  style: tt.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${dt.month}월 ${dt.day}일';
  }
}
