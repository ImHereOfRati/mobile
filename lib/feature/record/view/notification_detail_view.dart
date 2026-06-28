import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';

class NotificationDetailView extends StatelessWidget {
  final NotificationEntity? notification;

  const NotificationDetailView({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('알림 상세', style: tt.headlineSmall),
        centerTitle: true,
      ),
      body: notification == null
          ? Center(
              child: Text('알림 정보를 찾을 수 없습니다', style: tt.bodyMedium),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailCard(title: '제목', value: notification!.title, cs: cs),
                  SizedBox(height: 12.h),
                  _DetailCard(
                    title: '본문',
                    value: notification!.body,
                    cs: cs,
                    multiline: true,
                  ),
                  SizedBox(height: 12.h),
                  _DetailCard(
                    title: '보낸 사람',
                    value: notification!.senderNickname.isNotEmpty
                        ? '${notification!.senderNickname} (${notification!.senderEmail})'
                        : notification!.senderEmail,
                    cs: cs,
                  ),
                  if (notification!.path.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    _DetailCard(title: '이동 경로', value: notification!.path, cs: cs),
                  ],
                  SizedBox(height: 12.h),
                  _DetailCard(
                    title: '받은 시각',
                    value: _formatDateTime(notification!.createdAt),
                    cs: cs,
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final ColorScheme cs;
  final bool multiline;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.cs,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.labelLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: tt.bodyLarge,
            maxLines: multiline ? null : 3,
            overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
