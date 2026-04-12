import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/record/repository/geofence_record_entity.dart';
import 'package:iamhere/record/view/component/record_tile.dart';
import 'package:iamhere/record/view_model/geofence_record_view_model.dart';
import 'package:iamhere/shared/component/view_component/widgets/page_title.dart';

class RecordView extends ConsumerWidget {
  const RecordView({super.key});

  /// 수신자 JSON 문자열을 읽기 쉬운 형식으로 변환
  String _formatRecipients(String recipientsJson) {
    try {
      final List<dynamic> recipients = jsonDecode(recipientsJson);
      if (recipients.isEmpty) {
        return '수신자 없음';
      } else if (recipients.length == 1) {
        return recipients.first as String;
      } else {
        return '${recipients.first} 외 ${recipients.length - 1}명';
      }
    } catch (e) {
      return '수신자 정보 없음';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsyncValue = ref.watch(geofenceRecordViewModelProvider);

    final pageTitle = "내가 보낸 메시지";
    final pageDescription = "자동으로 전송된 기록";

    return Column(
      children: [
        // 1. 페이지 타이틀 (flex: 1)
        PageTitle(
          key: ValueKey(pageTitle),
          pageTitle: pageTitle,
          pageDescription: pageDescription,
          pageInfoCount: recordsAsyncValue.when(
            data: (records) => "${records.length}개 전송됨",
            loading: () => "로딩 중...",
            error: (_, __) => "오류",
          ),
          expandedWidgetFlex: 1,
        ),

        // 2. 기록 리스트 (ListView.builder 사용, flex: 4)
        Expanded(
          flex: 4,
          child: recordsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildToShowErrorWidget(err, ref),
            data: (records) {
              if (records.isEmpty) {
                return _buildToShowDataIsEmptyWidget();
              }
              return _buildToShowRecordToUserWidget(records);
            },
          ),
        ),
      ],
    );
  }

  ListView _buildToShowRecordToUserWidget(List<GeofenceRecordEntity> records) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final targetName = _formatRecipients(record.recipients);

        return RecordTile(
          tileKey: ValueKey('record_tile_${record.id}'),
          locationName: record.geofenceName,
          recordTime: record.createdAt,
          message: record.message,
          targetName: targetName,
          sendMachine: record.sendMachine,
        );
      },
    );
  }

  Center _buildToShowDataIsEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            '전송된 기록이 없습니다',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '지오펜스에 진입하면\n자동으로 기록이 저장됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Center _buildToShowErrorWidget(Object err, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              '기록 로드 실패',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(geofenceRecordViewModelProvider.notifier).refresh();
              },
              child: Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
