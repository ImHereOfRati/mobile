import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/record/repository/geofence_record_entity.dart';
import 'package:iamhere/record/view_model/geofence_record_view_model.dart';

class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── 페이지 헤더 ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildPageHeader(context, cs, recordsAsync),
        ),

        // ── 받은 알림 ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, cs, '받은 알림', 0),
        ),
        SliverToBoxAdapter(
          child: _buildEmptySection(context, cs, '받은 알림이 없습니다'),
        ),

        // ── 받은 친구 요청 ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, cs, '받은 친구 요청', 0),
        ),
        SliverToBoxAdapter(
          child: _buildEmptySection(context, cs, '받은 친구 요청이 없습니다'),
        ),

        // ── 나의 전송 기록 ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildSectionHeader(
            context,
            cs,
            '나의 전송 기록',
            recordsAsync.value?.length ?? 0,
          ),
        ),

        recordsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => SliverToBoxAdapter(
            child: _buildErrorState(context, cs, ref),
          ),
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
    final count = recordsAsync.value?.length ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록',
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '읽지 않은 알림과 요청을 확인하세요',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$count개의 읽지 않은 항목',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
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
    int unreadCount,
  ) {
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
                onTap: () {},
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
    final recipient = _formatRecipients(record.recipients);
    final title = '$recipient에게 ${record.geofenceName} 알림 전송 성공';
    final dateStr = _formatKoreanDate(record.createdAt);
    // 로컬 DB에 저장된 기록은 전송 성공으로 표시
    return Column(
      children: [
        InkWell(
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Text(
                            '✓ 전송 성공',
                            style: TextStyle(
                              fontFamily: 'BMHANNAAir',
                              fontSize: 12.sp,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' · $dateStr',
                            style: TextStyle(
                              fontFamily: 'BMHANNAAir',
                              fontSize: 12.sp,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20.r,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 0.5,
          thickness: 0.5,
          color: cs.onSurface.withValues(alpha: 0.1),
          indent: 20.w,
          endIndent: 20.w,
        ),
      ],
    );
  }

  // ── 에러 상태 ─────────────────────────────────────────────────────────
  Widget _buildErrorState(
    BuildContext context,
    ColorScheme cs,
    WidgetRef ref,
  ) {
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

  String _formatKoreanDate(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}년 ${dt.month}월 ${dt.day}일 $hour:$minute';
  }
}
