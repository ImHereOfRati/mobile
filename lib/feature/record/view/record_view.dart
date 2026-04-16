import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';

class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── 페이지 헤더 ───────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildPageHeader(context, cs, recordsAsync)),

        // ── 받은 알림 ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            context, cs, '받은 알림', 0,
            onViewAll: () => AppRoutes.goToRecordNotifications(context),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildEmptySection(context, cs, '받은 알림이 없습니다'),
        ),

        // ── 받은 친구 요청 ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            context, cs, '받은 친구 요청', 0,
            onViewAll: () => AppRoutes.goToRecordFriendRequests(context),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildEmptySection(context, cs, '받은 친구 요청이 없습니다'),
        ),

        // ── 나의 전송 기록 ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            context, cs, '나의 전송 기록',
            recordsAsync.value?.length ?? 0,
            onViewAll: () => AppRoutes.goToRecordSendHistory(context),
          ),
        ),

        recordsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) =>
              SliverToBoxAdapter(child: _buildErrorState(context, cs, ref)),
          data: (records) {
            if (records.isEmpty) {
              return SliverToBoxAdapter(
                child: _buildEmptySection(context, cs, '전송된 기록이 없습니다'),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildSendRecordItem(context, cs, records[index]),
                childCount: records.length,
              ),
            );
          },
        ),

        SliverToBoxAdapter(child: SizedBox(height: 32.h)),
      ],
    );
  }

  // ── 페이지 헤더 ───────────────────────────────────────────────────────
  Widget _buildPageHeader(
    BuildContext context,
    ColorScheme cs,
    AsyncValue<List<GeofenceRecordEntity>> recordsAsync,
  ) {
    final tt = Theme.of(context).textTheme;
    final count = recordsAsync.value?.length ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기록', style: tt.displayMedium),
          SizedBox(height: 4.h),
          Text(
            '읽지 않은 알림과 요청을 확인하세요',
            style: tt.bodyMedium,
          ),
          SizedBox(height: 4.h),
          Text(
            '$count개의 읽지 않은 항목',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ── 섹션 헤더 ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context,
    ColorScheme cs,
    String title,
    int unreadCount, {
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'GmarketSans',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '전체 보기',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            unreadCount > 0 ? '$unreadCount개 읽지 않음' : '읽지 않은 항목 없음',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ── 빈 섹션 ──────────────────────────────────────────────────────────
  Widget _buildEmptySection(
    BuildContext context,
    ColorScheme cs,
    String message,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 14.sp,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  // ── 나의 전송 기록 아이템 ─────────────────────────────────────────────
  Widget _buildSendRecordItem(
    BuildContext context,
    ColorScheme cs,
    GeofenceRecordEntity record,
  ) {
    final tt = Theme.of(context).textTheme;
    final recipient = _formatRecipients(record.recipients);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
              // 아이콘
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: cs.primary,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              // 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.geofenceName,
                      style: tt.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$recipient에게 전송 완료',
                      style: tt.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // 시간
              Text(
                _formatRelativeTime(record.createdAt),
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 에러 상태 ─────────────────────────────────────────────────────────
  Widget _buildErrorState(BuildContext context, ColorScheme cs, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록을 불러올 수 없습니다',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () =>
                ref.read(geofenceRecordViewModelProvider.notifier).refresh(),
            child: Text(
              '다시 시도',
              style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  // ── 유틸 ─────────────────────────────────────────────────────────────
  String _formatRecipients(String recipientsJson) {
    try {
      final list = jsonDecode(recipientsJson) as List<dynamic>;
      if (list.isEmpty) return '수신자';
      if (list.length == 1) return list.first as String;
      return '${list.first} 외 ${list.length - 1}명';
    } catch (_) {
      return '수신자';
    }
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
