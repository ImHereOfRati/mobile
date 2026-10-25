import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/date_time_formatter.dart';
import 'package:iamhere/core/view/async_state_view.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/repository/notification_entity.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:iamhere/feature/record/view/widget/activity_card.dart';
import 'package:iamhere/feature/record/viewmodel/record_detail_provider.dart';

/// 전송 기록 한 건의 상세.
class SendHistoryDetailPage extends ConsumerWidget {
  final ActivityLogService activityLog;
  final int recordId;

  const SendHistoryDetailPage({
    super.key,
    required this.activityLog,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sendRecordDetailProvider(activityLog, recordId);
    return _DetailScaffold<GeofenceRecordEntity>(
      value: ref.watch(provider),
      errorTitle: '전송 기록을 불러오지 못했어요',
      notFoundTitle: '기록을 찾지 못했어요',
      onRetry: () => ref.invalidate(provider),
      builder: (record) => _Detail(
        eyebrow: '전송 기록',
        title: record.geofenceName,
        body: record.message,
        badge: RecordStatusBadge(status: record.status),
        rows: [
          ('시간', DateTimeFormatter.dateTime(record.createdAt)),
          ('전송한 기기', record.sendMachine.description),
          if (record.lastError.isNotEmpty) ('실패 사유', record.lastError),
        ],
      ),
    );
  }
}

/// 이 기기가 받은 알림 한 건의 상세.
class NotificationDetailPage extends ConsumerWidget {
  final ActivityLogService activityLog;
  final int notificationId;

  const NotificationDetailPage({
    super.key,
    required this.activityLog,
    required this.notificationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = notificationDetailProvider(activityLog, notificationId);
    return _DetailScaffold<NotificationEntity>(
      value: ref.watch(provider),
      errorTitle: '알림을 불러오지 못했어요',
      notFoundTitle: '알림을 찾지 못했어요',
      onRetry: () => ref.invalidate(provider),
      builder: (notification) => _Detail(
        eyebrow: '받은 알림',
        title: notification.title,
        body: notification.body,
        rows: [
          ('시간', DateTimeFormatter.dateTime(notification.createdAt)),
          if (notification.senderAlias.isNotEmpty)
            ('보낸 사람', notification.senderAlias),
        ],
      ),
    );
  }
}

class _DetailScaffold<T> extends StatelessWidget {
  final AsyncValue<T?> value;
  final String errorTitle;
  final String notFoundTitle;
  final VoidCallback onRetry;
  final Widget Function(T item) builder;

  const _DetailScaffold({
    required this.value,
    required this.errorTitle,
    required this.notFoundTitle,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: AsyncStateView<T?>(
        value: value,
        errorTitle: errorTitle,
        onRetry: onRetry,
        builder: (item) => item == null
            ? ImHereStatePanel(
                glyph: ImHereGlyph.close,
                title: notFoundTitle,
                size: ImHereStateSize.large,
              )
            : builder(item),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final Widget? badge;
  final List<(String, String)> rows;

  const _Detail({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.badge,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.navToTitle),
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.xl),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                eyebrow,
                style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            if (badge != null) badge!,
          ],
        ),
        SizedBox(height: metrics.resolve(6)),
        Text(title, style: textTheme.titleLarge),
        if (body.isNotEmpty) ...[
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Text(body, style: textTheme.bodyLarge),
        ],
        SizedBox(height: metrics.resolve(ImHereSpace.lg)),
        const ImHereBorder(),
        for (final (label, value) in rows) ...[
          ImHereListRow(
            title: label,
            trailing: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: metrics.resolve(200)),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ),
          ),
          const ImHereBorder(tone: ImHereDividerTone.subtle),
        ],
      ],
    );
  }
}
