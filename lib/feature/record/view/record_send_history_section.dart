import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'component/record_empty_section.dart';
import 'component/record_error_section.dart';
import 'component/record_section_header.dart';
import 'component/send_record_overview_item.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

class RecordSendHistorySection extends StatelessWidget {
  final AsyncValue<List<GeofenceRecordEntity>> recordsAsync;
  final WidgetRef ref;
  final VoidCallback onViewAll;

  const RecordSendHistorySection({
    super.key,
    required this.recordsAsync,
    required this.ref,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: RecordSectionHeader(
            title: '내 활동 기록',
            unreadCount: recordsAsync.value?.length ?? 0,
            onViewAll: onViewAll,
          ),
        ),
        recordsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => SliverToBoxAdapter(
            child: RecordErrorSection(ref: ref),
          ),
          data: (records) {
            if (records.isEmpty) {
              return const SliverToBoxAdapter(
                child: RecordEmptySection(message: '전송된 기록이 없습니다'),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SendRecordOverviewItem(
                  record: records[index],
                ),
                childCount: records.length,
              ),
            );
          },
        ),
      ],
    );
  }
}
