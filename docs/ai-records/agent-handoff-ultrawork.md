# ImHere Mobile Agent Handoff

## 목적
- 이 문서는 다음 에이전트가 바로 이어서 작업할 수 있도록 현재 구현 상태, 남은 미구현/미완료 작업, 주요 파일, 검증 명령을 정리한 handoff 문서다.
- 기준 브랜치/작업 디렉터리: `C:\Project\ImHere\ImHereMobile`

## 이번 턴에서 반영된 내용

### 1. 약관 API 고정
- `GET /api/terms?isActive=true` 로 하드코딩 적용
- 파일: `lib/feature/terms/service/terms_request_service.dart`

### 2. 인증 방어 강화
- `pending_auth` 외에 auth snapshot 저장 구조 추가
- 저장 항목:
  - `pending_auth`
  - `auth_user_status`
  - `auth_is_active`
- 파일:
  - `lib/feature/auth/service/token_storage_service.dart`
  - `lib/feature/auth/service/auth_state.dart`
  - `lib/feature/auth/service/auth_state_provider.dart`
  - `lib/feature/auth/service/auth_service.dart`
  - `lib/feature/auth/service/auth_session_sync_service.dart`
  - `lib/feature/setting/service/dto/user_me_response_dto.dart`
  - `lib/feature/auth/service/dto/auth_response.dart`
  - `lib/feature/terms/service/dto/after_terms_agreement_auth_response_dto.dart`

### 3. 라우팅 방어 강화
- `unauthenticated`, `pending`, `inactive`, `authenticated` 분기 추가
- `inactive` 는 `/auth?reason=inactive` 로 보냄
- `pending` 는 `/terms-consent?redirect=...` 로 redirect 유지
- 파일:
  - `lib/infrastructure/routing/auth_redirect_policy.dart`
  - `lib/feature/auth/view/auth_view.dart`
  - `lib/feature/terms/view/terms_list_view.dart`

### 4. 활동 기록 즉시성 개선
- record 화면 polling 추가
- 파일: `lib/feature/record/view_model/geofence_record_view_model.dart`

### 5. geofence retry 품질 개선
- queue first retry backoff 수정
- pipeline drain single-flight 추가
- foreground periodic drain 추가
- 파일:
  - `lib/feature/geofence/background/geofence_delivery_queue_database_service.dart`
  - `lib/feature/geofence/background/geofence_delivery_pipeline.dart`
  - `lib/main.dart`

### 6. WorkManager 기반 background retry 골격 추가
- `workmanager` dependency 추가
- background runtime bootstrap 추가
- retry scheduler 추가
- worker dispatcher 추가
- 파일:
  - `pubspec.yaml`
  - `lib/feature/geofence/background/geofence_background_runtime.dart`
  - `lib/feature/geofence/background/geofence_retry_scheduler.dart`
  - `lib/feature/geofence/background/geofence_retry_workmanager.dart`
  - `lib/infrastructure/di/di_setup.dart`
  - `lib/main.dart`

### 7. departure / both 흐름 1차 구현
- runtime event 개념 추가
- geofence DB에 `awaiting_departure` 상태 추가
- OS geofence trigger mapping 변경
- callback 에서 arrival/departure/both 분기 처리
- queue snapshot 에 business event 저장
- record 에 실제 delivery event 저장
- UI에서 departure / both 선택 가능하게 변경
- 관련 파일:
  - `lib/feature/geofence/model/event_type.dart`
  - `lib/feature/geofence/model/delivery_event.dart`
  - `lib/feature/geofence/repository/geofence_entity.dart`
  - `lib/infrastructure/database/local_database_schema.dart`
  - `lib/infrastructure/database/service/geofence_database_service.dart`
  - `lib/feature/geofence/repository/geofence_repository.dart`
  - `lib/feature/geofence/repository/geofence_local_repository.dart`
  - `lib/feature/geofence/background/geofence_background_callback.dart`
  - `lib/feature/geofence/background/geofence_delivery_snapshot.dart`
  - `lib/feature/geofence/background/geofence_delivery_pipeline.dart`
  - `lib/feature/geofence/service/native_geofence_registrar.dart`
  - `lib/feature/geofence/service/fcm_arrival_service.dart`
  - `lib/feature/geofence/service/sms_notification_service.dart`
  - `lib/feature/geofence/service/sms_service.dart`
  - `lib/feature/geofence/service/record_service.dart`
  - `lib/feature/geofence/view_model/enroll/geofence_enroll_view_model.dart`
  - `lib/feature/geofence/view_model/main/geofence_view_model.dart`
  - `lib/feature/geofence/view/geofence_enroll/component/event/enroll_event_section.dart`
  - `lib/feature/geofence/view/geofence_enroll/component/fields/enroll_message_hint_banner.dart`
  - `lib/feature/geofence/view/geofence_enroll/component/fields/enroll_message_field.dart`
  - `lib/feature/geofence/view/geofence_enroll/component/details/enroll_details_section.dart`
  - `lib/feature/geofence/view/geofence_enroll/component/enroll_form_body.dart`
  - `lib/feature/geofence/view/geofence_list/component/geofence_tile_info.dart`
  - `lib/feature/geofence/view/geofence_list/component/geofence_tile.dart`
  - `lib/feature/geofence/view/geofence_list/component/geofence_list_tile.dart`
  - `lib/feature/record/repository/geofence_record_entity.dart`
  - `lib/feature/record/view/component/record_time_formatter.dart`
  - `lib/feature/record/view/send_history_list_view.dart`

### 8. Android manifest 보정
- `NativeGeofenceForegroundService` 의 `android.permission.BIND_JOB_SERVICE` 제거
- 파일: `android/app/src/main/AndroidManifest.xml`

### 9. FCM background isolate bootstrap 보강
- `firebaseMessagingBackgroundHandler` 에 plugin registrant 초기화 추가
- 파일: `lib/integration/fcm/fcm_message_handler.dart`

## 이미 통과한 타깃 테스트
- 아래 명령으로 통과 확인됨:

```powershell
flutter test "test\feature\terms\service\terms_list_request_service_test.dart" "test\feature\auth\service\auth_state_provider_test.dart" "test\feature\auth\service\token_storage_service_test.dart" "test\feature\auth\service\auth_service_test.dart" "test\feature\setting\service\user_me_service_test.dart" "test\feature\geofence\background\geofence_delivery_queue_database_service_test.dart" "test\infrastructure\database\local_database_schema_test.dart" "test\infrastructure\database\service\geofence_database_service_test.dart" "test\infrastructure\routing\auth_redirect_policy_test.dart" "test\feature\auth\view\auth_view_test.dart" "test\feature\geofence\service\native_geofence_registrar_test.dart"
```

## 아직 남은 작업 / 미완료 작업

### A. 인증
1. `forceLogout` 직후 라우터를 즉시 auth 로 돌리는 구조가 아직 약하다.
- 현재 문제:
  - `auth_token_refresh_coordinator.dart` 는 토큰만 지우고 `authStateProvider` 자체를 즉시 invalidate 하지 못함.
  - 현재는 start/resume 시 `AuthSessionSyncService` + `ref.invalidate(authStateProvider)` 로 늦게 회복하는 구조.
- 추천 방향:
  - Riverpod 바깥에서도 auth state refresh 이벤트를 발생시킬 수 있는 notifier/event bus 추가
  - 또는 auth state provider 자체를 notifier 기반으로 재구성

2. nullable backend field 처리 정책 정리 필요
- 현재:
  - login/activation 쪽은 비교적 적극적으로 `ACTIVE/true` 로 수렴
  - `users/my` sync 는 nullable 필드를 그대로 저장하는 방향이 아니도록 다시 검토 필요
- 다음 에이전트는 `AuthSessionSyncService` 와 `TokenStorageService.saveAuthSnapshot()` 정책을 재검토할 것

### B. WorkManager / background worker
1. `GeofenceRetryScheduler` 의 `replaceExisting` 동작을 실제 Android runtime 에서 검증 필요
- 파일:
  - `lib/feature/geofence/background/geofence_retry_scheduler.dart`
  - `lib/feature/geofence/background/geofence_retry_workmanager.dart`

2. 실제 terminated 상태에서 worker 가 queue 를 소모하는지 디바이스 검증 필요
- 확인 항목:
  - geofence callback 발생 후 실패 -> retry 예약 -> 앱 종료 상태 -> worker 실행 여부
  - reboot 이후 queue retry scheduling 여부

3. Android 쪽 추가 설정이 필요한지 최종 확인
- 현재는 manifest 수동 추가 없이 plugin merge 가 된다는 전제로 구현됨
- 실제 Android build / runtime 검증 필요

### C. departure / both
1. callback 와 lifecycle 전이 로직의 실기기 검증 필요
- 파일:
  - `lib/feature/geofence/background/geofence_background_callback.dart`
  - `lib/feature/geofence/background/geofence_delivery_pipeline.dart`
- 확인 포인트:
  - `arrival` 저장 후 `both` geofence 가 `awaiting_departure=true` 로 유지되는지
  - `departure` 발생 후 비활성화가 정상인지
  - custom message 비워둔 경우 arrival/departure 각각 다른 기본 문구로 나가는지

2. 기존 queue / record 데이터와의 호환성 점검 필요
- snapshot 은 `eventName -> deliveryEventType` fallback 이 있으나,
- record schema 는 `delivery_event_type` 신규 컬럼이므로 migration 검증 강화 필요

3. `geofence_view_model.saveGeofence()` 의 existing lookup 안전성 보강 고려
- 현재 `request.id != null` 일 때 `_repo.findAll().firstWhere(...)` 사용
- edge case 에서 못 찾으면 throw 가능
- 파일: `lib/feature/geofence/view_model/main/geofence_view_model.dart`

### D. 테스트 보강
아래 테스트는 아직 추가되지 않았거나 강화가 필요하다.

1. `terms` empty auto-activation 경로 widget test
- 대상: `lib/feature/terms/view/terms_list_view.dart`

2. `inactive` redirect / auth reason 노출 test
- 대상:
  - `lib/infrastructure/routing/auth_redirect_policy.dart`
  - `lib/feature/auth/view/auth_view.dart`

3. `awaiting_departure` migration / persistence test 강화
- 대상:
  - `test/infrastructure/database/local_database_schema_test.dart`
  - `test/infrastructure/database/service/geofence_database_service_test.dart`

4. delivery event record rendering test
- `delivery_event_type` 기반 label 이 올바른지 확인
- 대상:
  - `lib/feature/record/view/component/record_time_formatter.dart`
  - `lib/feature/record/view/send_history_list_view.dart`

5. background callback / pipeline unit test
- 대상:
  - `geofence_background_callback.dart`
  - `geofence_delivery_pipeline.dart`

### E. 정적 분석 / 전체 검증
아래는 아직 끝까지 완료하지 못했다.

```powershell
dart analyze lib/main.dart lib/feature/auth lib/feature/geofence lib/feature/terms lib/feature/setting/service lib/infrastructure/database lib/infrastructure/di lib/infrastructure/routing test/feature/auth test/feature/geofence/background test/feature/geofence/service test/feature/terms/service test/feature/setting/service test/infrastructure/database test/infrastructure/routing
```

필요하면 `flutter test` 전체도 한 번 더 수행할 것.

## 다음 에이전트 추천 작업 순서
1. `dart analyze` 완료
2. `terms empty auto-activation` widget test 추가
3. `awaiting_departure` schema / DB tests 추가
4. `inactive redirect` / `auth reason` 테스트 추가
5. Android 실기기에서 WorkManager + terminated retry 검증
6. departure / both 실기기 검증
7. 필요 시 `forceLogout -> 즉시 auth 이동` 구조 개선

## 참고 메모
- 현재 worktree 는 이미 더럽다. 이 문서 작성 이전에도 사용자가 작업하던 변경들이 섞여 있을 수 있다.
- 다른 변경을 되돌리지 말고, 필요한 파일만 좁게 건드리는 방식이 안전하다.
- 이번 턴에서 생성/수정된 generated 파일은 `build_runner` 한 번 실행된 상태다.

## 핵심 요약
- `PENDING` 토큰 우회는 1차적으로 막음.
- `isActive` snapshot 기반 auth gating 은 추가됨.
- `/api/terms?isActive=true` 는 반영됨.
- WorkManager 골격은 들어갔지만 실기기 검증은 남음.
- `departure/both` 1차 구현은 들어갔지만 callback/pipeline/runtime 검증과 테스트 보강이 남음.
