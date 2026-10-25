import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/friend/model/dto/friend_request_dto.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/model/type/friend_request_view_type.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_entity.dart';
import 'package:iamhere/feature/record/model/repository/notification_entity.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_overview_view_model.g.dart';

const recordOverviewPreviewCount = 3;

class RecordOverviewState {
  final List<NotificationEntity> notifications;
  final List<GeofenceRecordEntity> records;
  final List<FriendRequestDto> requests;

  const RecordOverviewState({
    required this.notifications,
    required this.records,
    required this.requests,
  });
}

@riverpod
class RecordOverviewViewModel extends _$RecordOverviewViewModel {
  late ActivityLogService _activity;
  late FriendService _friends;

  @override
  Future<RecordOverviewState> build(
    ActivityLogService activityLog,
    FriendService friendService,
  ) {
    _activity = activityLog;
    _friends = friendService;
    return _load();
  }

  /// 로딩 화면으로 돌아가지 않고 다시 읽는다. 앱으로 돌아왔을 때 호출한다.
  Future<void> refresh() async {
    try {
      final next = await _load();
      if (ref.mounted) state = AsyncData(next);
    } catch (error, stack) {
      AppLogger.error('Record overview refresh failed', error, stack);
    }
  }

  /// 세 목록은 서로 독립이다. 하나가 실패해도 나머지는 보여 주고, 전부 실패했을
  /// 때만 오류로 본다.
  Future<RecordOverviewState> _load() async {
    final results = await Future.wait<Object?>([
      _activity
          .notifications(limit: recordOverviewPreviewCount)
          .then<Object?>((page) => page.items)
          .catchError((Object error) => error),
      _activity
          .records(limit: recordOverviewPreviewCount)
          .then<Object?>((page) => page.items)
          .catchError((Object error) => error),
      _friends
          .loadRequests(0, FriendRequestViewType.received)
          .then<Object?>(
            (page) => page.items.take(recordOverviewPreviewCount).toList(),
          )
          .catchError((Object error) => error),
    ]);
    if (results.every((result) => result is Error || result is Exception)) {
      throw StateError('활동 기록을 불러오지 못했습니다');
    }
    return RecordOverviewState(
      notifications: results[0] is List<NotificationEntity>
          ? results[0] as List<NotificationEntity>
          : const [],
      records: results[1] is List<GeofenceRecordEntity>
          ? results[1] as List<GeofenceRecordEntity>
          : const [],
      requests: results[2] is List<FriendRequestDto>
          ? results[2] as List<FriendRequestDto>
          : const [],
    );
  }
}
