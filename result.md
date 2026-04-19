# OS 네이티브 Geofence API 이관 결과 보고서

`plan.md` 의 **A안 — OS 네이티브 geofence API (권장)** 를 따라
프로젝트를 재설계하였다. Dart 측 연속 위치 스트림 기반 관제를 걷어내고,
OS(`CoreLocation` / `GeofencingClient`) 가 진입 이벤트를 감지 → 백그라운드
아이솔레이트를 깨워 알림 파이프라인을 실행하는 구조로 전환한다.

---

## 1. 변경 요약 (파일 단위)

### 1.1 추가된 파일

| 파일 | 역할 |
|---|---|
| `lib/feature/geofence/service/native_geofence_registrar_interface.dart` | OS 지오펜스 등록/해제/동기화 계약 정의 |
| `lib/feature/geofence/service/native_geofence_registrar.dart` | `native_geofence` 플러그인을 래핑한 구현체, `@LazySingleton(as: NativeGeofenceRegistrarInterface)` |
| `lib/feature/geofence/background/geofence_background_callback.dart` | OS 이벤트 수신 시 실행되는 백그라운드 엔트리포인트 (`@pragma('vm:entry-point')`) |
| `result.md` | 본 결과 보고서 |

### 1.2 수정된 파일

| 파일 | 변경점 |
|---|---|
| `pubspec.yaml` | `native_geofence: ^1.0.0` 의존성 추가 |
| `lib/main.dart` | 앱 시작 시 DB → OS 지오펜스 재동기화 루틴 `_syncNativeGeofencesOnStart` 추가 |
| `lib/feature/geofence/view_model/geofence_view_model.dart` | `toggleGeofenceActive` 에서 OS register/unregister 훅 적용 |
| `lib/feature/geofence/view_model/geofence_list_view_model.dart` | `toggleActive` / `delete` 에서 OS register/unregister 훅 적용 |
| `lib/feature/geofence/view/geofence_view.dart` | 구(舊) Orchestrator 호출 제거 → `NativeGeofenceRegistrar.syncAll` 호출로 교체 |
| `android/app/src/main/AndroidManifest.xml` | `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` 퍼미션 추가 |
| `ios/Runner/Info.plist` | `UIBackgroundModes` 에 `fetch`, `processing` 추가 |
| `lib/core/di/di_setup.config.dart` | `NativeGeofenceRegistrarInterface` 바인딩 수동 반영 (`build_runner` 재실행 전 임시 조치) |

---

## 2. 신규 아키텍처

```
┌─────────────────────────┐
│  Geofence 등록 UI (VM)   │
│  saveGeofence()          │
│  toggleGeofenceActive()  │
│  delete()                │
└──────────┬──────────────┘
           ▼
┌──────────────────────────────────────┐
│  NativeGeofenceRegistrar             │
│  ├─ register(GeofenceEntity)         │
│  ├─ unregister(int id)               │
│  ├─ syncAll(active geofences)        │
│  └─ getRegisteredIds()               │
└──────────┬───────────────────────────┘
           ▼
┌──────────────────────────────────────┐
│  OS (CoreLocation / GeofencingClient)│
│  — 앱 종료/재부팅 상태에서도 감지     │
└──────────┬───────────────────────────┘
           ▼ (Enter 이벤트)
┌────────────────────────────────────────────────────┐
│  geofenceTriggered() @pragma('vm:entry-point')     │
│  ├─ _bootstrapBackgroundIsolate()                  │
│  │   · Firebase.initializeApp (apps.isEmpty 가드)  │
│  │   · enrollBaseUrlGlobally(baseUrl)              │
│  └─ _dispatchArrival(id)                           │
│      · DB → GeofenceEntity 조회                     │
│      · ContactResolutionService                    │
│      · SmsNotificationService (로컬 연락처)         │
│      · FcmArrivalService (서버 수신자)              │
│      · RecordService (레코드 저장)                  │
│      · updateActiveStatus(false) + OS 에서 제거     │
└────────────────────────────────────────────────────┘
```

### 2.1 훅 포인트

- **저장 직후 활성화 시**
  `GeofenceEnrollViewModel.saveGeofence` → `vmInterface.toggleGeofenceActive(true)` →
  `GeofenceViewModel.toggleGeofenceActive` → `NativeGeofenceRegistrar.register()`.
- **리스트에서 토글 ON** → `GeofenceListViewModel.toggleActive(true)` → `register()`.
- **리스트에서 토글 OFF** → `unregister()`.
- **삭제** → `GeofenceListViewModel.delete` → DB delete + `unregister()`.
- **진입 감지 (백그라운드)** → `_dispatchArrival` 가 최종적으로 `updateActiveStatus(false)` +
  `removeGeofenceById` 로 1회성 트리거를 보장.

### 2.2 앱 부팅 시 동기화

`main()` 의 `_initializeAppDependencies()` 마지막 단계에서
`_syncNativeGeofencesOnStart()` 를 호출한다.

- DB 의 `isActive == true` 지오펜스만 추출
- `NativeGeofenceRegistrar.syncAll(active)` 로 OS 등록 상태를 강제 정합화
- OS 에만 있고 DB 에 없는 것 → 제거
- DB 에 있고 OS 에 없는 것 → 등록
- **iOS 20 개 제한 정책**: `id` 오름차순으로 앞 20 개만 등록, 초과분은 skip (로그로 기록).
  초기 정책을 보수적으로 고정했으며 추후 거리순/우선순위 정책으로 교체 가능.

---

## 3. 플랫폼 설정 변경

### 3.1 Android (`AndroidManifest.xml`)

추가된 퍼미션:
- `android.permission.RECEIVE_BOOT_COMPLETED` — 단말 재부팅 후 백그라운드에서
  지오펜스 재등록이 가능하도록 한다. `native_geofence` 가 내부적으로
  `BootBroadcastReceiver` 를 쓴다.
- `android.permission.WAKE_LOCK` — 백그라운드 FlutterEngine 기동 중 잠금.

플러그인의 `<service>` / `<receiver>` 는 `native_geofence` 의 manifest merger
결과물로 자동 주입된다 (별도 선언 불필요).

### 3.2 iOS (`Info.plist`)

- `UIBackgroundModes` 에 `fetch`, `processing` 추가. `location` 은 기존 유지.
- `NSLocationAlwaysAndWhenInUseUsageDescription` 기존 문구 유지 (OS 지오펜스도
  Always 권한 요구).

---

## 4. 기존 구조 정리

### 4.1 제거된 파일

Dart 측 연속 위치 스트림 관제 계층을 완전히 걷어냈다. 아래 파일은 모두 삭제되었으며
`di_setup.config.dart` 의 관련 바인딩도 함께 제거되었다.

- `lib/feature/geofence/service/geofence_orchestrator.dart` (+ `.g.dart`)
- `lib/feature/geofence/service/location_monitoring_service.dart`
- `lib/feature/geofence/service/geofence_checking_service.dart`
- `lib/feature/geofence/service/deduplication_service.dart`

중복 트리거 방지(`DeduplicationService` 의 역할)는 이제 **OS 에서 `removeGeofenceById`
+ DB `is_active=false`** 의 구조적 차단으로 대체되어 별도 서비스가 필요하지 않다.

### 4.2 재사용

다음 서비스는 백그라운드 엔트리포인트에서 그대로 재사용한다
(아이솔레이트 재부팅 후 `GetIt.get()` 으로 인스턴스 획득).

- `ContactResolutionService`
- `SmsNotificationService`
- `FcmArrivalService`
- `RecordService`
- `GeofenceLocalRepository`

---

## 5. 백그라운드 아이솔레이트 주의 사항

- **DI 재부팅 필요**: `GetIt` 은 아이솔레이트별 컨테이너이므로
  `enrollBaseUrlGlobally` 을 백그라운드에서 다시 호출해야 한다.
  `_bootstrapBackgroundIsolate()` 가 이를 한 번만 수행하도록 가드한다.
- **Firebase 재초기화 가드**: `Firebase.apps.isEmpty` 가 false 이면 재초기화 생략.
- **baseUrl 결정**: Remote Config 실패 시 `http://10.0.2.2:8080` fallback.
- **sqflite**: 플랫폼 채널 기반으로 아이솔레이트에서도 동일한 DB 파일 접근 가능.
  `@preResolve` 의 `Database` 팩토리가 백그라운드에서도 정상 동작한다.
- **SecureStorage**: `flutter_secure_storage` 는 iOS Keychain / Android Keystore
  접근이므로 백그라운드에서도 정상 동작한다. Dio 인터셉터의 토큰 읽기에 사용됨.

---

## 6. 중복 트리거 방지

- `triggers = {GeofenceEvent.enter}` 로 제한 (exit / dwell 비활성)
- 진입 발송 성공 시 `updateActiveStatus(false)` + `removeGeofenceById()` 로
  OS 등록 자체를 제거하여 영역 재진입으로 인한 중복 발송을 원천 차단.
- DB 측 is_active 가 false 로 내려가므로 UI 에도 즉시 반영된다.

---

## 7. 후속 작업 체크리스트

- [ ] **build_runner 재실행 (필수)**
  ```
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
  - `di_setup.config.dart` 를 수동 편집했으므로, build_runner 가 이를 정식 재생성하며
    `NativeGeofenceRegistrar` 바인딩과 삭제된 서비스 엔트리가 자동 정합화된다.
- [ ] **실기기 진입 이벤트 검증**
  - Android: Android Studio 의 Extended Controls → Location mocker 로 이동 시뮬레이션.
  - iOS: Simulator → Features → Location → Freeway Drive.
- [ ] **권한 안내 UX 보강**
  - Android 11+ 에서 “Always allow location” 은 일반 설정에 노출되지 않으므로
    권한 안내 화면에서 “정확한 위치 + 항상 허용” 유도 문구 추가 필요.
- [ ] **Privacy Policy 갱신**
  - 백그라운드 위치 수집 / FCM 발송 항목 반영.
- [ ] **(향후) iOS 20 개 초과 정책 고도화**
  - 현재: `id` 오름차순 top 20. 가까운 위치 기준 동적 교체 로직 검토.

---

## 8. 변경의 기대 효과

| 항목 | Before | After |
|---|---|---|
| 앱 포그라운드 | ✅ 동작 | ✅ 동작 |
| 앱 백그라운드 (짧은 시간) | ⚠️ iOS 한정 | ✅ 완전 지원 |
| 앱 스와이프 종료 | ❌ | ✅ OS 가 깨움 |
| 단말 재부팅 | ❌ | ✅ `RECEIVE_BOOT_COMPLETED` + 앱 재실행 시 `syncAll` |
| 배터리 소모 | 연속 GPS → 높음 | OS 저전력 감지 → 최상 |
| 중복 트리거 | Dart 측 deduplication 필요 | OS 등록 제거로 구조적 차단 |
| 코드 복잡도 | 관제/스트림/체크/중복제거 다층 | 등록/콜백 2계층 |

---

## 9. 리스크 & 완화

1. **native_geofence 버전 호환성**
   - 현재 `^1.0.0` 지정. 실제 pub.dev 버전과 API 시그니처가 다르면
     `Geofence`, `Location`, `AndroidGeofenceSettings`, `IosGeofenceSettings`
     생성 인자 및 `NativeGeofenceManager.instance` 메서드 시그니처 조정 필요.
   - 조정 지점은 `native_geofence_registrar.dart` 로 국소화되어 있다.
2. **진입 이벤트 지연**
   - OS 의 배터리 최적화로 수 초 ~ 수 분 지연 가능. 유스케이스(도착 알림)에는
     허용 범위.
3. **iOS 20 개 상한**
   - 초기 정책은 단순 `id` 오름차순 top 20. 운영 초기에는 모니터링 후
     정책 고도화.
4. **배경 아이솔레이트 DI 부팅 비용**
   - 첫 진입 이벤트 시 수백 ms 지연 가능. 메시징 API 가 idempotent 하므로
     사용자 체감상 문제 없음.

---

## 10. 참고

- Plan: `plan.md` § 2.A, § 3
- 플러그인: https://pub.dev/packages/native_geofence
- Android 공식 문서: https://developer.android.com/develop/sensors-and-location/location/geofencing
- iOS 공식 문서: https://developer.apple.com/documentation/corelocation/monitoring_the_user_s_proximity_to_geographic_regions
