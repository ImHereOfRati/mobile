import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      subtitle: '$recipient에게 전송 완료',
      titleStyle: tt.headlineSmall,
      subtitleStyle: tt.bodyMedium,
      trailing: Text(RecordTimeFormatter.formatRelativeTime(record.createdAt), style: tt.bodySmall),
    );
  }
}
