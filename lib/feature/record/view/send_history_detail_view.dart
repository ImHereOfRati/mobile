import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/model/activity_record_status.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/view/component/record_time_formatter.dart';

class SendHistoryDetailView extends StatelessWidget {
  final GeofenceRecordEntity? record;

  const SendHistoryDetailView({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('활동 기록 상세')),
        body: Center(
          child: Text('기록 정보를 찾을 수 없습니다', style: tt.bodyMedium),
        ),
      );
    }

    final isArrival = record!.deliveryEventType == 'arrival';
    final eventColor = isArrival ? cs.primary : cs.secondary;
    final statusColor = _statusColor(cs, record!.status);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r, color: cs.onSurface),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          '활동 기록 상세',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 1. 헤더 카드 (Hero Section) ───
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    eventColor.withValues(alpha: 0.08),
                    eventColor.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: eventColor.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: eventColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          isArrival ? '진입' : '이탈',
                          style: tt.bodySmall?.copyWith(
                            color: eventColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          record!.status.label,
                          style: tt.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: eventColor,
                        size: 24.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          record!.geofenceName,
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    RecordTimeFormatter.formatActivityLabel(
                      locationName: record!.geofenceName,
                      deliveryEventType: record!.deliveryEventType,
                    ),
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ─── 2. 발송 메시지 카드 (Message Card) ───
            _PremiumCard(
              title: '발송 메시지',
              icon: Icons.chat_bubble_outline_rounded,
              indicatorColor: eventColor,
              child: Text(
                record!.message,
                style: tt.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            SizedBox(height: 16.h),

            // ─── 3. 수신 대상 및 전송 메타 정보 그리드 ───
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  _GridRow(
                    icon: Icons.people_alt_outlined,
                    title: '수신인',
                    value: RecordTimeFormatter.formatRecipients(record!.recipients),
                    cs: cs,
                    tt: tt,
                  ),
                  Divider(height: 24.h, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.4)),
                  _GridRow(
                    icon: Icons.devices_rounded,
                    title: '발송 기기',
                    value: record!.sendMachine.description,
                    cs: cs,
                    tt: tt,
                  ),
                  Divider(height: 24.h, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.4)),
                  _GridRow(
                    icon: Icons.access_time_rounded,
                    title: '발생 시각',
                    value: _formatDateTime(record!.createdAt),
                    cs: cs,
                    tt: tt,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ─── 4. 진단 및 오류 로그 (에러 발생 시 노출) ───
            if (record!.retryCount > 0 || record!.lastError.trim().isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: record!.status == ActivityRecordStatus.failed
                      ? cs.errorContainer.withValues(alpha: 0.6)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: record!.status == ActivityRecordStatus.failed
                        ? cs.error.withValues(alpha: 0.25)
                        : cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          record!.status == ActivityRecordStatus.failed
                              ? Icons.error_outline_rounded
                              : Icons.info_outline_rounded,
                          color: record!.status == ActivityRecordStatus.failed ? cs.error : cs.onSurfaceVariant,
                          size: 20.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '시스템 오류 진단',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: record!.status == ActivityRecordStatus.failed ? cs.error : cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (record!.retryCount > 0) ...[
                      SizedBox(height: 12.h),
                      Text(
                        '• 재시도 횟수: ${record!.retryCount}회',
                        style: tt.bodyMedium?.copyWith(
                          color: record!.status == ActivityRecordStatus.failed ? cs.onErrorContainer : cs.onSurface,
                        ),
                      ),
                    ],
                    if (record!.lastError.trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        '• 마지막 에러: ${record!.lastError.trim()}',
                        style: tt.bodyMedium?.copyWith(
                          fontFamily: 'Courier', // 에러 로그용 고정폭 글꼴
                          color: record!.status == ActivityRecordStatus.failed ? cs.error : cs.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme cs, ActivityRecordStatus status) {
    switch (status) {
      case ActivityRecordStatus.completed:
        return cs.primary;
      case ActivityRecordStatus.failed:
        return cs.error;
      case ActivityRecordStatus.pending:
        return cs.tertiary;
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _PremiumCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color indicatorColor;
  final Widget child;

  const _PremiumCard({
    required this.title,
    required this.icon,
    required this.indicatorColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5.w,
                color: indicatorColor,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18.r, color: cs.onSurface.withValues(alpha: 0.6)),
                          SizedBox(width: 8.w),
                          Text(
                            title,
                            style: tt.labelLarge?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;

  const _GridRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.r, color: cs.onSurface.withValues(alpha: 0.5)),
        SizedBox(width: 12.w),
        Text(
          title,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
