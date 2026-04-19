# Geofence 백그라운드 동작 지원 계획

## 1. 현황 분석

### 1.1 대상 모듈
- `lib/feature/geofence/service/geofence_orchestrator.dart` — Riverpod `@Riverpod(keepAlive: true)` 노티파이어. 위치 스트림 구독 → 지오펜스 진입 체크 → SMS/FCM 발송 → 레코드 저장 → 비활성화.
- `lib/feature/geofence/service/location_monitoring_service.dart` — `Geolocator.getPositionStream` 구독 래퍼.
- 관련 서비스: `GeofenceCheckingService`, `DeduplicationService`, `ContactResolutionService`, `SmsNotificationService`, `FcmArrivalService`, `RecordService`.

### 1.2 백그라운드 동작이 안 되는 이유

| 항목 | 현재 상태 | 백그라운드 관점 문제 |
|---|---|---|
| 실행 컨테이너 | 메인 Dart 아이솔레이트의 Riverpod ProviderScope | 앱 종료 시 ProviderContainer 소멸 → orchestrator 사라짐 |
| 위치 스트림 설정 | `LocationSettings(accuracy: high, distanceFilter: 10)` | Android/iOS 플랫폼별 백그라운드 옵션 미적용 |
| Android 매니페스트 | `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE_LOCATION` 퍼미션만 선언 | `<service>` 태그 없음, `RECEIVE_BOOT_COMPLETED` 없음 |
| iOS Info.plist | `UIBackgroundModes = [location]` 설정됨 | `allowBackgroundLocationUpdates` 런타임 설정 누락 |
| 백그라운드 패키지 | 없음 (`flutter_foreground_task`, `flutter_background_service`, `workmanager`, `native_geofence` 전부 미사용) | 별도 아이솔레이트/서비스 래핑 수단 없음 |
| 프로세스 재시작 복원 | 없음 | 앱 스와이프/재부팅 후 복원 불가 |

### 1.3 현재 동작 범위
- ✅ 앱 포그라운드 상태
- ⚠️ iOS에서 포그라운드 → 백그라운드 전환 직후 짧은 시간 (OS suspend 전까지)
- ❌ 사용자 스와이프 종료
- ❌ Android Doze 모드 / OEM 배터리 최적화
- ❌ 재부팅 후 복원
- ❌ 장시간 백그라운드 (iOS suspension)

---

## 2. 선택지 비교

### A안 · OS 네이티브 geofence API (⭐ 권장)

**개요**: OS에 지오펜스 영역을 등록. OS가 진입 이벤트 발생 시 백그라운드 아이솔레이트로 앱을 깨움.

**장점**
- 앱 종료/재부팅 상태에서도 동작
- 배터리 효율 최상 (OS가 cell tower / WiFi / 가속도계 기반 저전력 감지)
- ImHere 유스케이스(지점 진입 1회 알림)와 설계 의도가 정확히 일치

**단점**
- iOS 최대 20개 리전 제한
- Android 100개 제한 (실사용엔 충분)
- 플러그인 제약으로 진입 이벤트의 지연(수초~수분)이 있을 수 있음
- 기존 orchestrator 계층 상당 부분 재설계 필요

**작업 단계**

1. **패키지 선정 및 추가**
   - `native_geofence` (활발히 유지 중) 또는 동급 패키지 평가
   - `pubspec.yaml`에 의존성 추가

2. **백그라운드 엔트리포인트 작성** (신규 파일)
   - `lib/feature/geofence/background/geofence_background_callback.dart`
   - 최상위 함수, `@pragma('vm:entry-point')` 어노테이션
   - 아이솔레이트 전용 DI 부트스트랩: `enrollBaseUrlGlobally` 재실행 필요 (GetIt은 아이솔레이트별 격리됨)
   - `WidgetsFlutterBinding.ensureInitialized`, Firebase init, SharedPreferences/SecureStorage 접근성 확인
   - 진입 이벤트 수신 → `geofenceId` → DB에서 `GeofenceEntity` 조회 → 수신자 resolve → SMS/FCM 발송 → 레코드 저장 → `updateActiveStatus(false)`

3. **`NativeGeofenceRegistrar` 서비스 신설** (신규 파일)
   - `lib/feature/geofence/service/native_geofence_registrar.dart` + interface
   - `@lazySingleton`
   - 메서드:
     - `Future<void> register(GeofenceEntity geofence)` — OS에 등록
     - `Future<void> unregister(int geofenceId)` — OS에서 제거
     - `Future<void> syncAll(List<GeofenceEntity> activeGeofences)` — 전체 재동기화 (iOS 20개 제한 처리 포함)

4. **훅 포인트 적용**
   - `GeofenceViewModel.saveGeofence` → 활성 상태로 저장되면 `register`
   - `GeofenceViewModel.updateActiveStatus(id, true)` → `register`
   - `GeofenceViewModel.updateActiveStatus(id, false)` → `unregister`
   - `GeofenceViewModel.delete` → `unregister`

5. **iOS 20개 제한 대응**
   - 정책 결정 필요: 최근 등록순? 거리순? 사용자 우선순위?
   - `syncAll` 내부에서 상위 20개만 OS에 register, 나머지는 대기 큐
   - (향후) 사용자 위치 이동 시 가까운 지오펜스로 주기적 교체 — 초기 스코프 제외 가능

6. **Android 매니페스트**
   - 플러그인이 추가하는 `<service>`, `<receiver>` 병합 확인
   - `RECEIVE_BOOT_COMPLETED` 퍼미션 추가 + 재부팅 시 활성 지오펜스 재등록 로직
   - `POST_NOTIFICATIONS` (기존 선언됨) 활용

7. **iOS 설정**
   - `UIBackgroundModes = [location]` (기존 OK)
   - `NSLocationAlwaysAndWhenInUseUsageDescription` (기존 OK)
   - 플러그인이 요구하는 추가 키 확인

8. **기존 모듈 정리**
   - `GeofenceOrchestrator`: 제거 또는 "현장 테스트 모드"(라이브 위치 미리보기) 전용으로 축소
   - `LocationMonitoringService`: 필요 시 테스트 모드 전용으로 유지
   - `GeofenceCheckingService`, `DeduplicationService`: OS가 담당하므로 테스트 모드만
   - `ContactResolutionService`, `SmsNotificationService`, `FcmArrivalService`, `RecordService`: 백그라운드 콜백에서 재사용 (DI 재부팅 필수)

9. **DB 접근 안전성**
   - 백그라운드 아이솔레이트에서 sqflite 재오픈 → `preResolve` 경로가 아이솔레이트별로 문제 없는지 검증
   - 필요 시 `databaseFactoryFfi` 또는 동일 DB 파일에 다중 접근 가능성 확인

10. **FCM 발송 경로 검증**
    - 백그라운드 아이솔레이트에서 Dio + SecureStorage 토큰 접근이 가능해야 함
    - `flutter_secure_storage` 백그라운드 호환성 체크

11. **테스트 전략**
    - 수동: 기기에서 실제 지점 이동 시뮬레이션 (Android Location mocker, iOS Simulator Freeway drive)
    - 단위: `NativeGeofenceRegistrar` mock으로 훅 포인트 호출 검증
    - 통합: 백그라운드 엔트리포인트가 DB에서 지오펜스를 바르게 읽고 발송까지 완료하는지 격리 테스트

---

### B안 · Foreground Service로 현재 구조 래핑

**개요**: `GeofenceOrchestrator`의 연속 위치 스트림 모델을 유지하고, Android foreground service + iOS background mode로 OS 종료를 회피.

**장점**
- 기존 코드 보존율 높음 (orchestrator/location_service/checking/dedup 모두 재사용)
- 구현 복잡도 A안보다 낮음

**단점**
- Android에 상시 표시 알림 필요 — UX 부담
- 배터리 소모 크게 증가 (연속 위치 스트림)
- 앱이 스와이프되면 서비스도 종료됨 (Android 기종 별 편차)
- 재부팅 복원 여전히 별도 구현 필요

**작업 단계**

1. **패키지 추가**: `flutter_foreground_task` (또는 `flutter_background_service`)
2. **Foreground Task 엔트리포인트**: 최상위 `@pragma('vm:entry-point')` 함수 → `onStart`에서 DI 재부팅, `onRepeatEvent`에서 `_checkGeofences` 호출
3. **`LocationMonitoringService` 수정**:
   - `LocationSettings` → `AndroidSettings(foregroundNotificationConfig: ForegroundNotificationConfig(...))`
   - iOS: `AppleSettings(allowBackgroundLocationUpdates: true, pauseLocationUpdatesAutomatically: false, showBackgroundLocationIndicator: true)`
4. **AndroidManifest**:
   - `<service android:name="..." android:foregroundServiceType="location" android:exported="false" />` 추가
   - `RECEIVE_BOOT_COMPLETED` 추가
5. **시작/종료 훅**: 활성 지오펜스 수가 0 → 1로 바뀔 때 서비스 시작, 0이 될 때 중단
6. **사용자 알림**: persistent notification 문구/아이콘 디자인
7. **재부팅 복원**: BOOT_COMPLETED receiver → 서비스 재시작

---

### C안 · 하이브리드 (OS geofence + 근접 시 foreground)

**개요**: OS에 큰 반경(예: 500m) 지오펜스 등록 → 진입 시 foreground service 시작 → 정밀 측위로 실제 타겟 반경 체크 → 도착 이벤트 후 서비스 중단.

**장점**
- 평상시 배터리 최적 (OS가 저전력 감지)
- 근접 시에만 정밀 측위 → 정확도 확보
- iOS 20개 제한도 실효적으로 완화 (외곽 반경은 여유 있게 설정)

**단점**
- 복잡도 최상 — A안과 B안 모두 구현
- 상태 전이 (OS geofence ↔ foreground service) 버그 위험
- 디버깅 어려움

**작업 단계**: A안 + B안 전부. 초기 릴리스에 권장하지 않음.

---

## 3. 권장안과 로드맵

### 3.1 권장: A안

**근거**
- ImHere의 사용자 시나리오는 "특정 지점에 도착하면 지인에게 알림"으로 **진입 이벤트 단발성**. OS 네이티브 geofence가 정확히 이 목적으로 설계됨.
- 현재 연속 스트림 방식은 배터리를 불필요하게 소모하며, 백그라운드 지속성도 못 보장.
- A안은 신뢰성·배터리·kill survival 세 가지를 동시에 해결.

### 3.2 단계별 진행 제안

**Phase 1 — 기반 작업** (1~2일)
- `native_geofence` (혹은 선정된 플러그인) 추가 및 플랫폼별 smoke test
- 백그라운드 아이솔레이트에서 DI 부팅 가능성 검증 (GetIt + Firebase + sqflite + SecureStorage)

**Phase 2 — 등록/해제 연동** (1~2일)
- `NativeGeofenceRegistrar` + interface 작성
- `GeofenceViewModel` 훅 포인트 적용 (save / updateActiveStatus / delete)
- 앱 시작 시 활성 지오펜스 재동기화 로직

**Phase 3 — 백그라운드 콜백** (1~2일)
- 엔트리포인트 작성
- 수신자 resolve → SMS/FCM 발송 → 레코드 저장 → 비활성화 파이프라인 이관
- 실기기에서 진입 이벤트 발송 검증

**Phase 4 — 기존 orchestrator 정리** (0.5~1일)
- 테스트 모드로 축소 또는 제거
- 관련 테스트 정리

**Phase 5 — iOS 20개 제한 대응** (0.5~1일, 초기엔 정책만 고정)
- 우선순위 규칙 결정
- `syncAll`에서 상위 N개만 등록, 초과분은 비활성 대기 표시

**Phase 6 — 재부팅 복원** (0.5일)
- Android: BOOT_COMPLETED receiver → 재등록
- iOS: 자동 복원이지만 앱 첫 실행 시 sync 보장

**Phase 7 — 문서/정책 업데이트** (0.5일)
- `PolicyData.privacyPolicy`에 백그라운드 위치/FCM 언급 보강
- 설정 화면에 "백그라운드 위치 권한" 안내 추가

---

## 4. 선결정 항목 (사용자 확인 필요)

- [ ] A/B/C 중 어느 안으로 진행?
- [ ] `native_geofence` vs 다른 플러그인 선호?
- [ ] iOS 20개 초과 시 우선순위 정책 (최근순 / 거리순 / 사용자 지정)
- [ ] 기존 `GeofenceOrchestrator`를 완전 제거할지, 테스트 모드로 남길지
- [ ] Phase 5, Phase 6을 초기 릴리스에 포함할지, 후속 이터레이션으로 미룰지
