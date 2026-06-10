# 권한 요청 시점 매핑 (Phase 2 결과물)

원칙: 권한은 지금 필요한 기능 기준으로만 요청한다.
구분: `기본 사용 권한` vs `자동 전송 활성화 권한`.

## 권한별 요청 시점 vs 실제 사용 시점

| 권한 | 분류 | 요청 시점 (코드 기준) | 실제 사용 시점 |
|---|---|---|---|
| 위치 (whenInUse 이상) | 기본 사용 | 알림 만들기 진입 시 — `CenterAddButton._handleTap`, `GeofenceEmptyState._handleCreateTap`, `GeofenceListBody._handleCreateNew` | 등록 화면 지도 표시, 현재 위치 조회 |
| 위치 항상 허용 | 자동 전송 활성화 | 저장 시 isActive=true인 경우 `GeofenceEnrollView._ensureAlwaysPermission`, 카드 토글 ON 시 `GeofenceListBody._ensureAlwaysPermission`, 자동 전송 준비 화면(Permission Prep) | 백그라운드 지오펜스 감지 |
| 배터리 최적화 제외 | 자동 전송 활성화 | 자동 전송 준비 화면, 설정 → 배터리 최적화 제외 가이드 | 백그라운드 생존 (OS 절전 회피) |
| 푸시(FCM 알림) | 기존 기능 유지 | 로그인 후 FCM 토큰 등록 흐름 (`AuthViewModel.requestFCMTokenAndSendToServer`) | 본인 전송 결과 통보, 친구 요청 알림 |
| 연락처 | 기존 기능 유지 | 수신자 선택 화면 진입 시 | 로컬 수신자 선택 |
| SMS | 기존 기능 유지 | 자동 전송 실행 경로 | 백그라운드 SMS 발송 |

## 정책 요약
1. 로그인/온보딩에서는 어떤 권한도 요청하지 않는다 (푸시 토큰 등록 제외).
2. 알림 저장 자체는 최소 위치 권한만으로 가능하다.
3. `위치 항상 허용` + `배터리 최적화 제외`는 자동 전송을 켜는 순간에만 요구한다.
4. 자동 전송 미준비 상태로도 저장은 허용하고, 저장 완료 시트에서 `자동 전송 켜기` CTA로 유도한다.
5. 권한 진입점은 Permission Prep(자동 전송 준비) 허브로 모은다: 메인 준비 상태 카드, 등록 저장 흐름, 설정.

## 1차 퍼널에서 다루는 권한 범위
- 핵심: 최소 위치 권한, 위치 항상 허용, 배터리 최적화 제외.
- 푸시/연락처/SMS는 기존 기능 유지 범위로만 다룬다.
