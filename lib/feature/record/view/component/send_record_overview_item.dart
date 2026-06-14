import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/model/activity_record_status.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

import 'record_overview_item_base.dart';
import 'record_time_formatter.dart';

class SendRecordOverviewItem extends StatelessWidget {
  final GeofenceRecordEntity record;

  const SendRecordOverviewItem({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final recipient = RecordTimeFormatter.formatRecipients(record.recipients);
    final statusText = _statusText(record.status);
    final retryText = _retryText(record);
    final errorText = _errorText(record);

    return RecordOverviewItemBase(
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(Icons.location_on_rounded, color: cs.primary, size: 20.r),
      ),
      title: record.geofenceName,
      subtitle: '$recipient에게 $statusText',
      titleStyle: tt.headlineSmall,
      subtitleStyle: tt.bodyMedium,
      footer: (retryText == null && errorText == null)
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (retryText != null)
                  Text(retryText, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                if (errorText != null)
                  Text(errorText, style: tt.bodySmall?.copyWith(color: cs.error), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
      trailing: Text(RecordTimeFormatter.formatRelativeTime(record.createdAt), style: tt.bodySmall),
    );
  }

  String _statusText(ActivityRecordStatus status) {
    switch (status) {
      case ActivityRecordStatus.completed:
        return '전송 완료';
      case ActivityRecordStatus.failed:
        return '전송 실패';
      case ActivityRecordStatus.pending:
        return '전송 대기';
    }
  }

  String? _retryText(GeofenceRecordEntity record) {
    if (record.retryCount <= 0) return null;

    return record.status == ActivityRecordStatus.failed
        ? '재시도 $record.retryCount회 후 최종 실패'
        : '재시도 $record.retryCount회 진행 중';
  }

  String? _errorText(GeofenceRecordEntity record) {
    final error = record.lastError.trim();
    if (error.isEmpty) return null;

    return record.status == ActivityRecordStatus.failed
        ? '실패 사유: $error'
        : '최근 오류: $error';
  }
}
