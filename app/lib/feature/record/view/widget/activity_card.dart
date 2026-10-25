import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/record/model/type/activity_record_status.dart';

/// 활동 한 건을 보여 주는 카드. 제목, 본문, 보조 정보(시간 등), 상태 배지 한 개.
class ActivityCard extends StatelessWidget {
  final String title;
  final String body;
  final String meta;
  final Widget? badge;
  final VoidCallback? onTap;
  final List<Widget> actions;

  const ActivityCard({
    super.key,
    required this.title,
    required this.body,
    required this.meta,
    this.badge,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ImHereSurface(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(title, style: textTheme.titleSmall)),
              if (badge != null) ...[
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                badge!,
              ],
            ],
          ),
          if (body.isNotEmpty) ...[
            SizedBox(height: metrics.resolve(6)),
            Text(body, style: textTheme.bodyMedium),
          ],
          SizedBox(height: metrics.resolve(6)),
          Text(
            meta,
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            Wrap(
              spacing: metrics.resolve(ImHereSpace.xs),
              runSpacing: metrics.resolve(ImHereSpace.xs),
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

/// 전송 상태 배지. 상태마다 색 의미가 다르다.
class RecordStatusBadge extends StatelessWidget {
  final ActivityRecordStatus status;

  const RecordStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return ImHereBadge(
      label: status.label,
      tone: switch (status) {
        ActivityRecordStatus.completed => ImHereBadgeTone.success,
        ActivityRecordStatus.failed => ImHereBadgeTone.error,
        ActivityRecordStatus.pending => ImHereBadgeTone.neutral,
      },
      size: ImHereBadgeSize.medium,
    );
  }
}
