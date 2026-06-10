# Phase 9 Domain Model Draft

## Activity Record
- `completed`: 저장/전송이 정상 완료된 기록
- `failed`: 전송 실패 기록(향후 서버/로컬 실패 이력 연동)
- `pending`: 대기 중 기록(향후 재시도/큐 상태 연동)

## Event / Repeat
- `EventType`: `도착`, `출발`, `도착/출발 모두`
- `RepeatType`: `반복 안 함`, `매일`, `평일`, `주말`, `직접 설정`

## Auto Send Readiness
- `ready`: 자동 전송 준비 완료
- `needsAttention`: 위치 항상 허용 또는 배터리 최적화 제외가 필요

## UI Rules
- 기록 탭은 사용자에게 `활동 기록`으로 노출한다.
- 성공 기록은 `전송 완료`로 통일한다.
- 실패/보류는 실제 데이터가 생기기 전까지 placeholder 로만 정의한다.
- 빠른 생성 UX는 연락처 선택을 기본값으로 둔다.

## API Split Notes
- 백엔드 없이 가능한 것: 로컬 기록, 수신자 선택, 준비 상태 표시
- API 필요 범위: 실패/보류 원인, 재시도 이력, 테스트 알림, 서버 진단
