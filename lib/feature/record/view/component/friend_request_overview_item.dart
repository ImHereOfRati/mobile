import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

import 'record_overview_item_base.dart';

class FriendRequestOverviewItem extends StatelessWidget {
  final ReceivedFriendRequestResponseDto request;

  const FriendRequestOverviewItem({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => AppRoutes.goToRecordFriendRequests(context),
      child: RecordOverviewItemBase(
        leading: CircleAvatar(
          radius: 20.r,
          backgroundColor: cs.primary.withValues(alpha: 0.1),
          child: Text(
            request.requesterNickname.isNotEmpty ? request.requesterNickname[0] : '?',
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ),
        title: request.requesterNickname,
        subtitle: request.requesterEmail,
        titleStyle: tt.headlineSmall,
        subtitleStyle: tt.bodyMedium,
      ),
    );
  }
}
