import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/view_model/notification_view_model.dart';

class NotificationListView extends ConsumerWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationViewModelProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '받은 알림',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _confirmDeleteAll(context, ref),
            icon: Icon(Icons.delete_outline, size: 22.r),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState(cs)
            : ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                itemCount: notifications.length,
                itemBuilder: (context, index) =>
                    _buildNotificationItem(context, cs, tt, notifications[index]),
              ),
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
        error: (_, __) => _buildErrorState(cs, ref),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48.r,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 12.h),
          Text(
            '받은 알림이 없습니다',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '알림을 불러올 수 없습니다',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () =>
                ref.read(notificationViewModelProvider.notifier).refresh(),
            child: Text(
              '다시 시도',
              style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    NotificationEntity notification,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
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
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: cs.primary,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: tt.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      notification.body,
                      style: tt.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.senderNickname.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        notification.senderNickname,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _formatRelativeTime(notification.createdAt),
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('알림 삭제', style: tt.displaySmall),
        content: Text(
          '모든 알림을 삭제할까요?\n삭제된 알림은 복구할 수 없습니다.',
          style: tt.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ref
                  .read(notificationViewModelProvider.notifier)
                  .deleteAll();
            },
            child: Text('삭제', style: TextStyle(color: errorColor)),
          ),
        ],
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
