import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

import 'setting_components.dart';
import 'setting_layout_components.dart';

const String _sectionTitle = '전송 진단';
const String _lastSendTitle = '마지막 자동 전송';
const String _noRecord = '아직 없음';
const String _manufacturerNote =
    '일부 기기(삼성, 샤오미 등)는 제조사 절전 설정이 자동 전송을 막을 수 있어요. '
    '전송이 누락되면 제조사 절전 설정에서 ImHere를 제외해주세요.';
const String _diagnosisPlaceholder = '자세한 전송 진단 기능은 준비 중이에요.';

/// 설정 화면의 전송 진단 섹션.
/// 로컬 기록으로 표시 가능한 수준(마지막 전송 결과)만 보여주고,
/// 서버 진단 데이터 영역은 placeholder 로 남겨둔다.
class SettingDiagnosisSection extends ConsumerWidget {
  const SettingDiagnosisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(geofenceRecordViewModelProvider);
    final lastSendLabel = recordsAsync.maybeWhen(
      data: (records) => records.isEmpty
          ? _noRecord
          : '${records.first.geofenceName} · ${_formatTime(records.first.createdAt)}',
      orElse: () => _noRecord,
    );

    return SettingSection(
      title: _sectionTitle,
      items: [
        SettingItem(
          title: _lastSendTitle,
          trailingText: lastSendLabel,
          onTap: () => AppRoutes.goToRecordSendHistory(context),
        ),
        _buildNote(context),
      ],
    );
  }

  Widget _buildNote(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final noteStyle = TextStyle(
      fontFamily: 'BMHANNAAir',
      fontSize: 12.sp,
      color: cs.onSurface.withValues(alpha: 0.55),
      letterSpacing: -0.12,
      height: 1.5,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 13.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_manufacturerNote, style: noteStyle),
          SizedBox(height: 6.h),
          Text(_diagnosisPlaceholder, style: noteStyle),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '${time.month}월 ${time.day}일 $hh:$mm';
  }
}
