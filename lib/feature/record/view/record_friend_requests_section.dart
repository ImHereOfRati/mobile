import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/friend/service/dto/received_friend_request_response_dto.dart';

import 'component/friend_request_overview_item.dart';
import 'component/record_empty_section.dart';
import 'component/record_section_header.dart';

class RecordFriendRequestsSection extends StatelessWidget {
  final AsyncValue<List<ReceivedFriendRequestResponseDto>> requestsAsync;
  final VoidCallback onViewAll;

  const RecordFriendRequestsSection({
    super.key,
    required this.requestsAsync,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '받은 친구 요청',
            unreadCount: requestsAsync.value?.length ?? 0,
            onViewAll: onViewAll,
          ),
        ),
        requestsAsync.when(
        loading: () => const SliverToBoxAdapter(
          child: Center(child: ImHereLoadingIndicator(height: 28)),
        ),
          error: (_, __) => const SliverToBoxAdapter(
            child: RecordEmptySection(message: '친구 요청을 불러올 수 없습니다'),
          ),
          data: (requests) {
            if (requests.isEmpty) {
              return const SliverToBoxAdapter(
                child: RecordEmptySection(message: '받은 친구 요청이 없습니다'),
              );
            }
            final preview = requests.take(3).toList();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => FriendRequestOverviewItem(
                  request: preview[index],
                ),
                childCount: preview.length,
              ),
            );
          },
        ),
      ],
    );
  }
}
