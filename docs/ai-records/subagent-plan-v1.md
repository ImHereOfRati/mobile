# Sub-agent 구현 계획 v1

작성 기준: `agent-handoff-ultrawork.md` 잔여 작업 세분화.  
병렬 실행 가능 에이전트: A1~A7 모두 독립 실행 가능. 의존 없음.

---

## A1 — Static Analysis Fix

**도구**: cavecrew-builder (또는 일반 에이전트)  
**목표**: `dart analyze` 전 범위 통과

### 실행 명령

```powershell
dart analyze lib/main.dart lib/feature/auth lib/feature/geofence lib/feature/terms lib/feature/setting/service lib/infrastructure/database lib/infrastructure/di lib/infrastructure/routing test/feature/auth test/feature/geofence/background test/feature/geofence/service test/feature/terms/service test/feature/setting/service test/infrastructure/database test/infrastructure/routing
```

### 작업 내용
1. 위 명령 실행 → stderr/stdout 수집
2. `error` 및 `warning` 각각 파일:라인 단위로 분류
3. 각 오류 최소 수정 원칙으로 fix (코드 구조 변경 금지)
4. fix 후 동일 명령 재실행 → 오류 0개 확인

### 완료 조건
- `dart analyze` 명령이 `No issues found!` 또는 hint만 남긴 상태
- 기존 테스트 suite 통과 유지

### 주의
- `// ignore:` 주석으로 suppress 금지. 실제 fix만.
- generated 파일(`.g.dart`, `.mocks.dart`) 에서 나오는 오류는 `build_runner` 재실행으로 해결.

---

## A2 — ForceLogout → 즉시 Auth 이동

**도구**: 일반 에이전트  
**목표**: `forceLogout()` 호출 즉시 `authStateProvider` invalidate → 라우터가 `/auth` 로 이동

### 현재 문제
`AuthTokenRefreshCoordinator.forceLogout()` 은 Riverpod 외부(DI 레이어)에 있어서 `ref.invalidate(authStateProvider)` 를 직접 호출할 수 없음. 현재는 토큰만 지우고, app resume/start 시에야 `AuthSessionSyncService` 가 돌아와서 늦게 상태가 갱신됨.

### 읽을 파일 (컨텍스트)
- `lib/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart`
- `lib/feature/auth/service/auth_state_provider.dart`
- `lib/feature/auth/service/token_storage_service.dart`
- `lib/infrastructure/di/di_setup.dart`
- `lib/main.dart`

### 구현 방향 (권장: ChangeNotifier 기반 이벤트 채널)

#### Step 1: 이벤트 채널 생성
`lib/feature/auth/service/auth_invalidation_notifier.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthInvalidationNotifier extends ChangeNotifier {
  void requestInvalidation() {
    notifyListeners();
  }
}
```

#### Step 2: Coordinator에 주입
`auth_token_refresh_coordinator.dart`

```dart
// 생성자에 AuthInvalidationNotifier 추가
final AuthInvalidationNotifier _authInvalidationNotifier;

AuthTokenRefreshCoordinator(
  this._tokenStorage,
  this._refresher,
  this._retrier,
  this._authInvalidationNotifier,  // 추가
);

Future<void> forceLogout(...) async {
  await _tokenStorage.deleteAllTokens();
  _authInvalidationNotifier.requestInvalidation();  // 추가
  _retrier.failAll(dioException);
  handler.reject(dioException);
}
```

#### Step 3: AppWidget 또는 main.dart 에서 구독
앱 최상단 ConsumerStatefulWidget 의 `initState` 에서:

```dart
final notifier = getIt<AuthInvalidationNotifier>();
notifier.addListener(_onAuthInvalidated);

void _onAuthInvalidated() {
  ref.invalidate(authStateProvider);
}
```

#### Step 4: DI 등록 확인
`di_setup.dart` 에 `AuthInvalidationNotifier` 가 `@lazySingleton` 이므로 자동 등록됨.  
`build_runner` 재실행 필요.

### 수정할 파일
| 파일 | 작업 |
|------|------|
| `lib/feature/auth/service/auth_invalidation_notifier.dart` | 신규 생성 |
| `lib/infrastructure/network/instance/module/auth_token_refresh_coordinator.dart` | 생성자 + forceLogout 수정 |
| `lib/main.dart` 또는 최상단 app widget | listener 등록 |
| `lib/infrastructure/di/di_setup.dart` | build_runner 재생성 필요 |

### 완료 조건
- `auth_token_refresh_coordinator_test.dart` 의 기존 테스트 통과
- mock `AuthInvalidationNotifier` 로 `requestInvalidation()` 호출 여부 검증 테스트 1개 추가

### 주의
- `addListener` 는 widget이 dispose 될 때 반드시 `removeListener` 해야 함.
- Riverpod ref 가 필요하므로 최상단 ConsumerStatefulWidget 이어야 함.

---

## A3 — saveGeofence firstWhere Safety Fix

**도구**: cavecrew-builder  
**목표**: `request.id != null` 인데 DB에 해당 id 없을 때 StateError 대신 명시적 예외

### 읽을 파일
- `lib/feature/geofence/view_model/main/geofence_view_model.dart` (line 46)

### 현재 코드 (line 46)
```dart
final existing = request.id == null
    ? null
    : (await _repo.findAll()).firstWhere((g) => g.id == request.id);
```

### 수정 코드
```dart
final existing = request.id == null
    ? null
    : (await _repo.findAll()).where((g) => g.id == request.id).firstOrNull;
```

line 58 의 `existing?.isActive ?? false` 와 line 59 의 `existing?.awaitingDeparture ?? false` 는 이미 null-safe → 변경 불필요.

line 95~98 의 update 후 reload 도 동일 패턴:
```dart
// 현재
final updated = all.firstWhere((g) => g.id == request.id);
// 수정
final updated = all.where((g) => g.id == request.id).firstOrNull;
if (updated == null) return finalEntity;  // 없으면 OS 등록 스킵
```

### 수정할 파일
- `lib/feature/geofence/view_model/main/geofence_view_model.dart`

### 완료 조건
- `dart analyze` 통과
- `firstOrNull` 이 `package:collection` 없이 사용 가능한지 확인 (`Iterable.firstOrNull` 은 Dart 2.18+ 에서 기본 제공)

---

## A4 — DB Migration Tests v7/v8

**도구**: 일반 에이전트  
**목표**: `awaiting_departure` (v7) 과 `delivery_event_type` (v8) 컬럼의 신규/마이그레이션 경로 모두 테스트

### 읽을 파일 (컨텍스트 필수)
- `test/infrastructure/database/local_database_schema_test.dart` (기존 테스트 패턴 참조)
- `test/infrastructure/database/_helpers/test_database_factory.dart` (헬퍼 구조 파악)
- `lib/infrastructure/database/local_database_schema.dart` (v7, v8 migration 로직)
- `lib/infrastructure/database/local_database_properties.dart` (테이블명 상수)

### 추가할 테스트 (기존 파일에 추가)
`test/infrastructure/database/local_database_schema_test.dart`

#### group: `LocalDatabaseSchema (신규 설치, onCreate)` 내 추가
```dart
test('geofence 테이블에 awaiting_departure 컬럼이 존재한다', () async {
  final cols = await _columnNames(db, LocalDatabaseProperties.geofenceTableName);
  expect(cols, contains('awaiting_departure'));
});

test('records 테이블에 delivery_event_type 컬럼이 존재한다', () async {
  final cols = await _columnNames(db, LocalDatabaseProperties.recordTableName);
  expect(cols, contains('delivery_event_type'));
});
```

#### group: `LocalDatabaseSchema (v6 → v8, onUpgrade)` 신규 추가
`TestDatabaseFactory` 에 `openMigratedFromV6()` 헬퍼가 없으면 인라인으로 구현:

```dart
group('LocalDatabaseSchema (v6 → 최신, onUpgrade)', () {
  // v6 DB: records 테이블에 retry_count, last_error 있지만
  //         awaiting_departure, delivery_event_type 없는 상태
  Future<Database> _openV6() async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, _) async {
          // v6 까지의 schema 수동 구성
          await db.execute(
            'CREATE TABLE geofence '
            '(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, '
            'address TEXT DEFAULT "", lat REAL, lng REAL, radius REAL, '
            'message TEXT, contact_ids TEXT, is_active INTEGER DEFAULT 0, '
            'event_type TEXT DEFAULT "arrival", repeat_type TEXT DEFAULT "none", '
            'custom_days_bitmask INTEGER)',
          );
          await db.execute(
            'CREATE TABLE records '
            '(id INTEGER PRIMARY KEY AUTOINCREMENT, geofence_id INTEGER, '
            'geofence_name TEXT, message TEXT, recipients TEXT, created_at TEXT, '
            'send_machine TEXT, status TEXT DEFAULT "completed", delivery_key TEXT, '
            'retry_count INTEGER DEFAULT 0, last_error TEXT DEFAULT "")',
          );
        },
      ),
    );
    await db.close();
    return db;
  }

  test('v6 → v8 마이그레이션 후 geofence.awaiting_departure 컬럼이 추가된다', () async {
    final handle = await TestDatabaseFactory.openMigratedFrom(6);
    addTearDown(handle.dispose);

    final cols = await _columnNames(
      handle.database,
      LocalDatabaseProperties.geofenceTableName,
    );
    expect(cols, contains('awaiting_departure'));
  });

  test('v6 → v8 마이그레이션 후 records.delivery_event_type 컬럼이 추가된다', () async {
    final handle = await TestDatabaseFactory.openMigratedFrom(6);
    addTearDown(handle.dispose);

    final cols = await _columnNames(
      handle.database,
      LocalDatabaseProperties.recordTableName,
    );
    expect(cols, contains('delivery_event_type'));
  });

  test('기존 geofence 행은 awaiting_departure 기본값 0 으로 보존된다', () async {
    final handle = await TestDatabaseFactory.openMigratedFrom(
      6,
      seed: (db) async {
        await db.insert('geofence', {
          'name': '테스트',
          'lat': 37.0, 'lng': 127.0, 'radius': 100.0,
          'message': '도착', 'contact_ids': '[]', 'is_active': 0,
          'event_type': 'arrival', 'repeat_type': 'none',
          'address': '서울',
        });
      },
    );
    addTearDown(handle.dispose);

    final rows = await handle.database.query(
      LocalDatabaseProperties.geofenceTableName,
    );
    expect(rows, hasLength(1));
    expect(rows.first['awaiting_departure'], 0);
  });
});
```

### TestDatabaseFactory 확장 필요 여부
`_helpers/test_database_factory.dart` 를 읽고:
- `openMigratedFrom(int fromVersion)` 메서드가 없으면 추가
- 기존 `openMigratedFromV1()` 패턴과 동일하게 구현 (fromVersion 만 파라미터화)

### 완료 조건
- 새로 추가한 테스트 모두 `flutter test` 통과
- 기존 테스트 영향 없음

---

## A5 — Auth Routing / View 테스트 보강

**도구**: 일반 에이전트  
**목표**: `inactive` redirect 경로 및 auth view 의 reason 파라미터 렌더링 검증

### A5-1: auth_redirect_policy_test.dart 확장
**파일**: `test/infrastructure/routing/auth_redirect_policy_test.dart`  
**기존 테스트 보존 후 추가**:

```dart
test('inactive 사용자가 보호된 경로에 접근하면 /auth?reason=inactive 로 redirect', () {
  final result = policy.resolve(
    authState: AuthState.inactive,
    matchedLocation: AppRoutes.geofence,
    requestedUri: Uri.parse(AppRoutes.geofence),
  );
  expect(result, '${AppRoutes.auth}?reason=inactive');
});

test('inactive 사용자가 이미 /auth 에 있으면 redirect 없음', () {
  final result = policy.resolve(
    authState: AuthState.inactive,
    matchedLocation: AppRoutes.auth,
    requestedUri: Uri.parse(AppRoutes.auth),
  );
  expect(result, isNull);
});

test('pending 사용자가 termsConsent 에 있으면 redirect 없음', () {
  final result = policy.resolve(
    authState: AuthState.pending,
    matchedLocation: AppRoutes.termsConsent,
    requestedUri: Uri.parse(AppRoutes.termsConsent),
  );
  expect(result, isNull);
});

test('인증 사용자가 auth 접근 시 redirect 파라미터가 있으면 해당 경로로 이동', () {
  final result = policy.resolve(
    authState: AuthState.authenticated,
    matchedLocation: AppRoutes.auth,
    requestedUri: Uri.parse('${AppRoutes.auth}?redirect=/record'),
  );
  expect(result, '/record');
});

test('인증 사용자가 auth 접근 시 redirect 파라미터 없으면 geofence 로 이동', () {
  final result = policy.resolve(
    authState: AuthState.authenticated,
    matchedLocation: AppRoutes.auth,
    requestedUri: Uri.parse(AppRoutes.auth),
  );
  expect(result, AppRoutes.geofence);
});
```

### A5-2: auth_view_test.dart 확장
**읽을 파일**: 
- `test/feature/auth/view/auth_view_test.dart` (기존 패턴 파악)
- `lib/feature/auth/view/auth_view.dart` (inactive reason 렌더링 코드 확인)

**auth_view.dart 읽기 후**: `reason=inactive` 쿼리 파라미터가 있을 때 UI에서 어떤 위젯/텍스트를 노출하는지 확인하고 그에 맞는 widget test 작성.

만약 `auth_view.dart` 가 `reason` 파라미터를 아직 처리하지 않으면:
- `auth_view.dart` 에 `GoRouterState.of(context).uri.queryParameters['reason']` 읽어서 `inactive` 일 때 안내 텍스트 노출 코드 추가
- 그 후 widget test 작성

### 완료 조건
- `flutter test test/infrastructure/routing/auth_redirect_policy_test.dart` 통과
- `flutter test test/feature/auth/view/auth_view_test.dart` 통과

---

## A6 — Background Callback / Pipeline Unit Tests

**도구**: 일반 에이전트  
**목표**: `geofence_background_callback.dart` 와 `geofence_delivery_pipeline.dart` 핵심 분기 unit test

### 읽을 파일 (필수)
- `lib/feature/geofence/background/geofence_background_callback.dart`
- `lib/feature/geofence/background/geofence_delivery_pipeline.dart`
- `lib/feature/geofence/model/event_type.dart`
- `lib/feature/geofence/model/delivery_event.dart`
- `lib/feature/geofence/repository/geofence_entity.dart`
- `lib/feature/geofence/background/geofence_delivery_snapshot.dart`
- `lib/feature/geofence/background/geofence_delivery_queue_database_service.dart`
- 기존 유사 테스트 패턴: `test/feature/geofence/background/geofence_delivery_queue_database_service_test.dart`

### A6-1: geofence_background_callback_test.dart (신규)
**파일**: `test/feature/geofence/background/geofence_background_callback_test.dart`

테스트 대상 함수: `_shouldHandleEvent()` (private → 로직을 외부로 꺼내거나 통합 테스트로 우회)

**전략**: `_shouldHandleEvent` 는 private 이므로 `_dispatchTriggeredEvent` 전체를 mock으로 주입하거나,  
`GeofenceBackgroundCallback` 클래스로 리팩토링 후 테스트. 단, 리팩토링 범위는 이 agent 에 한정.

또는 **더 현실적 접근**: `GeofenceDeliveryPipeline` mock + `GeofenceLocalRepository` mock 주입 후  
`geofenceTriggered(params)` 전체 실행을 테스트. `bootstrapBackgroundRuntime()` 은 GetIt 수동 setup으로 우회.

```dart
// 테스트 케이스
group('_shouldHandleEvent (via geofenceTriggered integration)', () {
  // arrival 전용 geofence → enter event → pipeline.enqueue 호출됨
  test('arrival 전용: enter event 발생 시 pipeline enqueue 호출', ...);

  // departure 전용 geofence → exit event → pipeline.enqueue 호출됨
  test('departure 전용: exit event 발생 시 pipeline enqueue 호출', ...);

  // both geofence, awaitingDeparture=false → enter → enqueue 호출됨
  test('both: awaitingDeparture=false, enter → enqueue 호출', ...);

  // both geofence, awaitingDeparture=false → exit → enqueue 안 호출됨
  test('both: awaitingDeparture=false, exit → enqueue 스킵', ...);

  // both geofence, awaitingDeparture=true → exit → enqueue 호출됨
  test('both: awaitingDeparture=true, exit → enqueue 호출', ...);

  // inactive geofence → 모든 event → enqueue 안 호출됨
  test('inactive geofence → enqueue 스킵', ...);
});
```

### A6-2: geofence_delivery_pipeline_test.dart (신규)
**파일**: `test/feature/geofence/background/geofence_delivery_pipeline_test.dart`

Mock 대상:
- `GeofenceDeliveryQueueDatabaseService`
- `ContactResolutionService`
- `GeofenceLocalRepository`
- `NativeGeofenceRegistrarInterface`
- `SmsNotificationService`
- `FcmArrivalService`
- `RecordService`
- `GeofenceRetryScheduler`

```dart
// 테스트 케이스
group('GeofenceDeliveryPipeline', () {
  test('SMS 성공 시 record completed + queue completed + geofence deactivate', ...);

  test('FCM 성공 시 record completed + queue completed', ...);

  test('모든 전송 실패 시 queue reschedule + record pending 업데이트', ...);

  test('maxRetry 초과 시 record failed + geofence active 복원', ...);

  // both + arrival 성공 시
  test('both + arrival 성공: awaitingDeparture=true 설정, geofence deactivate 안 함', ...);

  // both + departure 성공 시
  test('both + departure 성공: geofence deactivate', ...);

  test('수신자 없음: 성공으로 간주 → record completed', ...);

  test('동시 processPending 호출: single-flight 보장 (in-flight 중복 실행 없음)', ...);
});
```

### 완료 조건
- `flutter test test/feature/geofence/background/` 통과
- mock 파일 `build_runner` 생성 필요 → `@GenerateMocks` 어노테이션 후 실행

---

## A7 — Record Rendering Tests

**도구**: cavecrew-builder 또는 일반 에이전트  
**목표**: `RecordTimeFormatter` 의 `formatActivityLabel` 과 `formatRecipients` 검증

### 읽을 파일
- `lib/feature/record/view/component/record_time_formatter.dart`

### 생성할 파일
`test/feature/record/view/component/record_time_formatter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/record/view/component/record_time_formatter.dart';

void main() {
  group('RecordTimeFormatter.formatActivityLabel', () {
    test('deliveryEventType=arrival → {location} 도착 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '집',
          deliveryEventType: 'arrival',
        ),
        '집 도착 감지',
      );
    });

    test('deliveryEventType=departure → {location} 출발 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '학교',
          deliveryEventType: 'departure',
        ),
        '학교 출발 감지',
      );
    });

    test('알 수 없는 타입 → {location} 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '회사',
          deliveryEventType: 'unknown',
        ),
        '회사 감지',
      );
    });
  });

  group('RecordTimeFormatter.formatRecipients', () {
    test('빈 리스트 → "수신자"', () {
      expect(RecordTimeFormatter.formatRecipients('[]'), '수신자');
    });

    test('단일 수신자 → 이름 그대로', () {
      expect(RecordTimeFormatter.formatRecipients('["엄마"]'), '엄마');
    });

    test('복수 수신자 → "첫번째 외 N명"', () {
      expect(RecordTimeFormatter.formatRecipients('["엄마","아빠","누나"]'), '엄마 외 2명');
    });

    test('잘못된 JSON → "수신자" 폴백', () {
      expect(RecordTimeFormatter.formatRecipients('invalid json'), '수신자');
    });
  });

  group('RecordTimeFormatter.formatRelativeTime', () {
    test('1분 미만 → "방금 전"', () {
      final now = DateTime.now().subtract(const Duration(seconds: 30));
      expect(RecordTimeFormatter.formatRelativeTime(now), '방금 전');
    });

    test('1시간 미만 → "N분 전"', () {
      final now = DateTime.now().subtract(const Duration(minutes: 5));
      expect(RecordTimeFormatter.formatRelativeTime(now), '5분 전');
    });

    test('24시간 미만 → "N시간 전"', () {
      final now = DateTime.now().subtract(const Duration(hours: 3));
      expect(RecordTimeFormatter.formatRelativeTime(now), '3시간 전');
    });

    test('7일 미만 → "N일 전"', () {
      final now = DateTime.now().subtract(const Duration(days: 2));
      expect(RecordTimeFormatter.formatRelativeTime(now), '2일 전');
    });
  });
}
```

### 완료 조건
- `flutter test test/feature/record/view/component/record_time_formatter_test.dart` 통과

---

## A8 — Nullable Field 정책 보강 (AuthSessionSyncService)

**도구**: cavecrew-builder  
**목표**: `syncIfSignedIn()` 에서 `myInfo.isActive == null` 일 때 기존 값 보존

### 현재 문제
`UserMeResponse` 의 `isActive` 가 서버에서 null 로 내려오면 `saveAuthSnapshot(isActive: null)` →  
`saveIsActive(null)` → `_storage.delete(key: _isActiveKey)` → 다음 앱 실행 시 `getIsActive()` 가 null 반환 → `AuthState.authenticated` (의도치 않게 통과)

### 읽을 파일
- `lib/feature/auth/service/auth_session_sync_service.dart`
- `lib/feature/auth/service/token_storage_service.dart`
- `lib/feature/setting/service/dto/user_me_response_dto.dart`

### 수정 방향
`AuthSessionSyncService.syncIfSignedIn()` 에서 null 필드는 기존 저장 값을 유지:

```dart
Future<bool> syncIfSignedIn() async {
  final accessToken = await _tokenStorage.getAccessToken();
  if (accessToken == null || accessToken.isEmpty) return false;

  try {
    final myInfo = await _userMeService.fetchMyInfo();
    if (myInfo == null) return false;

    // null 이면 기존 값 보존 (delete 하지 않음)
    final effectiveIsActive = myInfo.isActive ?? await _tokenStorage.getIsActive() ?? true;

    await _tokenStorage.saveAuthSnapshot(
      userStatus: myInfo.userStatus,
      isActive: effectiveIsActive,
    );
    return true;
  } catch (e, st) {
    AppLogger.error('인증 세션 동기화 실패', e, st);
    return false;
  }
}
```

### 완료 조건
- `flutter test test/feature/setting/service/user_me_service_test.dart` 기존 통과 유지
- `dart analyze` 통과

---

## 실행 순서 권장

```
병렬 1차: A1 + A3 + A7 + A8   (빠르고 scope 작음)
병렬 2차: A4 + A5              (테스트 추가, 중간 규모)
병렬 3차: A6                   (mock 생성 + pipeline 테스트, 규모 큼)
순차 마지막: A2                 (구조 변경 포함, 영향 범위 넓음)
```

## 에이전트 공통 주의사항

1. **100줄/클래스 2개/private 4개 규칙**: 파일이 기준 초과하면 개발자(라티)에게 먼저 질문.
2. **수정 최소화**: 해당 agent 의 목표 범위 밖 코드 건드리지 않음.
3. **build_runner**: `@GenerateMocks` 추가 시 반드시 `dart run build_runner build --delete-conflicting-outputs` 실행.
4. **기존 테스트 보존**: 기존 테스트 삭제/변경 금지. 추가만 허용.
5. **worktree 더러움**: handoff 문서 이전 변경도 포함되어 있음. 불필요한 파일 되돌리지 말 것.
