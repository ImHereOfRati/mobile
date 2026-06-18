import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/common/component/layout/page_title.dart';

import 'gps_status_card.dart';

const String _mainTitle = '내 알림';
const String _mainDescription = '도착/출발하면 자동으로 알려줄 알림을 관리해요';
const String _registeredCount = '개 등록됨';
const String _loading = '로딩 중...';
const String _error = '오류';

class GeofenceHeader extends ConsumerWidget {
  const GeofenceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofencesAsyncValue = ref.watch(geofenceListViewModelProvider);

    return PageTitle(
      title: _mainTitle,
      description: _mainDescription,
      infoCount: geofencesAsyncValue.when(
        data: (g) => "${g.length}$_registeredCount",
        loading: () => _loading,
        error: (_, __) => _error,
      ),
      bottomSpacing: 12.h,
      actions: [const GPSStatusCard()],
    );
  }
}
