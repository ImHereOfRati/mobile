import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';
import 'package:iamhere/feature/friend/view_model/friend_restriction_view_model.dart';

class FriendRestrictionListView extends ConsumerWidget {
  const FriendRestrictionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(friendRestrictionViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '차단/거절 목록',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: stateAsync.when(
        data: (restrictions) => restrictions.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 48.r,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                    SizedBox(height: 12.h),
                    Text(
                      '차단/거절한 사용자가 없습니다',
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 15.sp,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                itemCount: restrictions.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) => _buildRestrictionTile(
                    context, ref, cs, restrictions[index]),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
        error: (_, __) =>
            const Center(child: Text('목록을 불러오는 중 오류가 발생했습니다.')),
      ),
    );
  }

  Widget _buildRestrictionTile(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
    FriendRestrictionResponseDto restriction,
  ) {
    final typeLabel =
        restriction.restrictionType == 'BLOCK' ? '차단' : '거절';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.error.withValues(alpha: 0.12),
            child: Icon(Icons.block, size: 20.r, color: cs.error),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      restriction.targetNickname,
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 10.sp,
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  restriction.targetEmail,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32.h,
            child: OutlinedButton(
              onPressed: () =>
                  _onUnblock(context, ref, restriction),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                side: BorderSide(color: cs.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                '해제',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onUnblock(
    BuildContext context,
    WidgetRef ref,
    FriendRestrictionResponseDto restriction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          '차단 해제',
          style: TextStyle(fontFamily: 'GmarketSans', fontSize: 17.sp),
        ),
        content: Text(
          '${restriction.targetNickname}님의 차단을 해제할까요?',
          style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final vm = ref.read(friendRestrictionViewModelProvider.notifier);
    final success = await vm.unblock(restriction.friendRestrictionId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(success
              ? '${restriction.targetNickname}님의 차단이 해제되었습니다'
              : '차단 해제에 실패했습니다')),
    );
  }
}
