import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/view/component/record_tile.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';

class SendHistoryListView extends ConsumerWidget {
  const SendHistoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('나의 전송 기록', style: tt.headlineSmall),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _confirmDeleteAll(context, ref),
            icon: Icon(Icons.delete_outline, size: 22.r),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) => records.isEmpty
            ? _buildEmptyState(cs, tt)
            : ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) =>
                    _buildRecordTile(records[index]),
              ),
        loading: () => Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
        error: (_, __) => _buildErrorState(cs, tt, ref),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48.r,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          SizedBox(height: 12.h),
          Text(
            '전송 기록이 없습니다',
            style: tt.bodyLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '기록을 불러올 수 없습니다',
            style: tt.bodyMedium,
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () =>
                ref.read(geofenceRecordViewModelProvider.notifier).refresh(),
            child: Text('다시 시도', style: tt.labelLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(GeofenceRecordEntity record) {
    return RecordTile(
      locationName: record.geofenceName,
      recordTime: record.createdAt,
      message: record.message,
      targetName: _formatRecipients(record.recipients),
      sendMachine: record.sendMachine,
    );
  }

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

  void _confirmDeleteAll(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final errorColor = Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('전송 기록 삭제', style: tt.displaySmall),
        content: Text(
          '모든 전송 기록을 삭제할까요?\n삭제된 기록은 복구할 수 없습니다.',
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
                  .read(geofenceRecordViewModelProvider.notifier)
                  .deleteAll();
            },
            child: Text('삭제', style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
  }
}
