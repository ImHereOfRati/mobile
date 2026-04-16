import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/feature/friend/view_model/friend_request_view_model.dart';

class RecordFriendRequestListView extends ConsumerWidget {
  const RecordFriendRequestListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(friendRequestViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '받은 친구 요청',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: stateAsync.when(
        data: (requests) => requests.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_disabled_outlined,
                      size: 48.r,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '받은 친구 요청이 없습니다',
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
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: requests.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) =>
                    _buildRequestTile(context, ref, cs, requests[index]),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
        error: (_, __) =>
            const Center(child: Text('요청 목록을 불러오는 중 오류가 발생했습니다.')),
      ),
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
    ReceivedFriendRequestResponseDto request,
  ) {
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
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              request.requesterNickname.isNotEmpty
                  ? request.requesterNickname[0]
                  : '?',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterNickname,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  request.requesterEmail,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _buildActionButton(
            context,
            ref,
            label: '수락',
            color: cs.primary,
            onPressed: () => _onAccept(context, ref, request.friendRequestId),
          ),
          SizedBox(width: 6.w),
          _buildActionButton(
            context,
            ref,
            label: '거절',
            color: cs.error,
            onPressed: () => _onReject(context, ref, request.friendRequestId),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept(
      BuildContext context, WidgetRef ref, int requestId) async {
    final vm = ref.read(friendRequestViewModelProvider.notifier);
    final success = await vm.acceptRequest(requestId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '친구 요청을 수락했습니다' : '수락에 실패했습니다')),
    );
  }

  Future<void> _onReject(
      BuildContext context, WidgetRef ref, int requestId) async {
    final vm = ref.read(friendRequestViewModelProvider.notifier);
    final success = await vm.rejectRequest(requestId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '친구 요청을 거절했습니다' : '거절에 실패했습니다')),
    );
  }
}
