# 도착 자동 알림 백그라운드 실행 전략

## 결론
- 이 기능의 핵심은 "백그라운드에서 감지"가 아니라 "감지 후 전송까지 잃지 않는 것"이다.
- 현재 앱은 권한 준비 UX, 배터리 최적화 안내, 활동 기록, 재시도용 네트워크 계층을 이미 갖추고 있다.
- 아직 남은 건 네이티브 geofence 콜백에서 이벤트를 영속화하고, 재시도 가능한 작업 큐로 넘기는 실행 계층이다.

## 현재 구현 상태
- `위치 항상 허용` 요청 게이트가 있다. `lib/feature/user_permission/view_model/location_permission_gate.dart`
- `배터리 최적화 제외` 상태와 안내 화면이 있다. `lib/feature/user_permission/model/auto_send_readiness.dart`
- 자동 전송 준비 상태를 `ready / needsAttention` 으로 계산한다. `lib/feature/user_permission/model/auto_send_readiness.dart`
- 준비 상태 카드와 배터리 상태 문구가 설정/지오펜스 화면에 반영돼 있다.
- 기록 쪽은 `활동 기록` 용어와 성공 기록 중심 UX로 정리돼 있다.
- 네트워크는 `retryDio` 와 재시도 코디네이터가 있어 후속 작업 재처리 기반이 있다.

## 남은 실제 작업
1. geofence callback에서 즉시 서버 호출하지 말고 이벤트를 로컬 큐에 적재한다.
2. 큐 이벤트에 `geofenceId`, `eventType`, `createdAt`, `dedupeKey`, `retryCount` 를 둔다.
3. WorkManager 또는 동등한 백그라운드 실행 단위로 큐를 소모한다.
4. 성공 시 기록 저장, geofence 비활성화, 큐 완료 처리를 한 번에 마친다.
5. 실패 시 네트워크 복구/앱 재실행/부팅 이후에 다시 시도한다.
6. 필요하면 짧은 Foreground Service 로 승격할 수 있게 분기만 남겨둔다.

## 권한별 역할
- 항상 허용: 앱이 닫힌 상태에서도 도착 위치를 감지하기 위한 필수 권한
- 배터리 최적화 제외: Doze / App Standby / OEM 절전 정책으로 인한 후속 작업 종료 완화
- 알림 권한: 상태 표시, 실패/보류 안내, 필요 시 Foreground Service 노출 기반
- 부팅 완료 수신: 재부팅 후 활성 도착 알림 재등록
- wake lock: 이벤트 직후 CPU를 잠깐 깨워 후속 처리 기회 확보

## 운영 원칙
- 목표를 `즉시 보내기`가 아니라 `결국 반드시 보내기`로 둔다.
- 위치 감지와 서버 전송을 같은 작업으로 묶지 않는다.
- 실패는 숨기지 말되, 사용자 UI는 불안감을 키우지 않게 `활동 기록`과 준비 상태로만 드러낸다.
- 제조사별 절전 정책 차이는 진단 카드에서 설명한다.

## UX 설명 원칙
- 항상 허용: `앱을 닫고 이동 중이어도 도착을 감지하려면 필요해요.`
- 배터리 최적화 제외: `도착을 감지한 뒤 자동 전송이 중간에 끊기지 않게 해요.`
- 실패 상태: 사용자에게 원인 추정 대신 다음 행동만 제시한다.

## 관련 문서
- `docs/ai-records/permission-timing-map.md`
- `docs/ai-records/phase-9-domain-model.md`
- `docs/ai-records/ui-transition-plan.md`

## 실행 순서
1. 백그라운드 로그 포인트 세분화
2. geofence callback 처리 최소화
3. pending event 큐 설계
4. WorkManager 기반 재시도 구조 설계
5. 권한 UX를 기능 활성화형으로 재정리
6. 설정 화면에 진단 상태 카드 추가
