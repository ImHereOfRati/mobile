import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/model/activity_record_status.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

class RecordTile extends StatelessWidget {
  final String locationName;
  final DateTime recordTime;
  final String message;
  final String targetName;
  final SendMachine sendMachine;
  final ActivityRecordStatus status;
  final int retryCount;
  final String lastError;

  const RecordTile({
    super.key,
    required this.locationName,
    required this.recordTime,
    required this.message,
    required this.targetName,
    required this.sendMachine,
    required this.status,
    required this.retryCount,
    required this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final badgeColor = _badgeColor(cs);
    final deliveryLabel = _deliveryLabel();
    final trimmedError = lastError.trim();

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
                     color: badgeColor.withValues(alpha: 0.12),
                     borderRadius: BorderRadius.circular(980.r),
                   ),
                   child: Text(
                     status.label,
                     style: tt.bodySmall?.copyWith(
                       color: badgeColor,
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

            if (retryCount > 0 || trimmedError.isNotEmpty) ...[
              _buildDiagnosticLine(context, retryCount, trimmedError),
              SizedBox(height: 12.h),
            ],

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
                Text('$targetName에게 $deliveryLabel', style: tt.bodyMedium),

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

  Color _badgeColor(ColorScheme cs) {
    switch (status) {
      case ActivityRecordStatus.completed:
        return cs.primary;
      case ActivityRecordStatus.failed:
        return cs.error;
      case ActivityRecordStatus.pending:
        return cs.tertiary;
    }
  }

  String _deliveryLabel() {
    switch (status) {
      case ActivityRecordStatus.completed:
        return '전송 완료';
      case ActivityRecordStatus.failed:
        return '전송 실패';
      case ActivityRecordStatus.pending:
        return '전송 대기';
    }
  }

  Widget _buildDiagnosticLine(
    BuildContext context,
    int retryCount,
    String trimmedError,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final parts = <String>[];

    if (retryCount > 0) {
      parts.add(
        status == ActivityRecordStatus.failed
            ? '재시도 $retryCount회 후 최종 실패'
            : '재시도 $retryCount회 진행 중',
      );
    }
    if (trimmedError.isNotEmpty) {
      parts.add(
        status == ActivityRecordStatus.failed
            ? '실패 사유: $trimmedError'
            : '최근 오류: $trimmedError',
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: status == ActivityRecordStatus.failed
            ? cs.error.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        parts.join('  '),
        style: tt.bodySmall?.copyWith(
          color: status == ActivityRecordStatus.failed ? cs.error : cs.onSurface,
        ),
      ),
    );
  }
}
