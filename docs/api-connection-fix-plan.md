# API 연결 수정 계획

## 전제
- [x] 로그인/재가입 로직은 완료된 상태로 간주
- [x] `admin` 이 포함된 API는 범위에서 제외
- [x] 단건 약관 조회 기능은 제거된 상태
- [x] 단일 약관 동의 기능은 제거된 상태
- [ ] Swagger 기준으로 남은 모든 연결부를 재정렬
- [x] 공통 응답 포맷은 `lib/common/base/api_response` 기준으로 재사용하거나 필요한 최소 범위만 수정

## 공통 응답 포맷 정리
- [x] `ApiResponse<T>`를 모든 서버 응답의 최상위 공통 래퍼로 유지
- [x] `SliceResponse<T>`를 `content`, `hasNext` 구조 응답의 표준으로 확정
- [x] `PageResponse<T>`는 실제 Swagger에서 쓰는 엔드포인트에만 제한적으로 유지
- [x] `raw list` 응답을 처리하는 공통 원칙 수립
- [x] 서비스 레이어에서 `body['data']`를 임의로 `List`/`Map`으로 단정하는 코드 제거용 공통 파서 준비
- [x] 엔드포인트별 응답 타입 표 작성
- [x] `lib/common/base/api_response/api_response_parser.dart` 추가
- [x] 수정 원칙: 공통 포맷 변경보다 서비스 파싱 보정이 더 작으면 서비스 쪽 우선 수정

## 응답 형태 기준안
- [x] `ApiResponse<List<T>>` 사용 대상 정리
- [x] `ApiResponse<SliceResponse<T>>` 사용 대상 정리
- [x] `ApiResponse<T>` 단건 객체 응답 대상 정리
- [x] `ApiResponse<void>` 성공 응답 대상 정리
- [x] `204`, `202`, `201` 등 비-200 성공 코드 처리 기준 정리

## 엔드포인트별 응답 기준

| 구분 | 대상 엔드포인트 | 공통 타입 | 비고 |
| --- | --- | --- | --- |
| 단건 객체 | `/api/users/my`, `/api/auth/login`, `/api/auth/registration`, `/api/auth/refresh`, `/api/auth/activation`, `/api/friendships/{id}`, `/api/friends/requests/{id}`, `/api/friends/requests/{id}/accept` | `ApiResponse<T>` | `data`가 단일 객체 |
| raw list | `/api/terms`, `/api/notifications` | `ApiResponse<List<T>>` | `data`가 배열 |
| slice | `/api/users`, `/api/friendships`, `/api/friends/requests`, `/api/friends/restrictions` | `ApiResponse<SliceResponse<T>>` | `data.content`, `data.hasNext` |
| void/null data | `/api/notifications`, `/api/notifications/batch`, `/api/fcm-tokens`, `/api/friendships/{id}`, `/api/friendships/{id}/block`, `/api/friends/restrictions/{id}` | `ApiResponse<void>` 또는 성공 코드만 확인 | `data: null`, 성공 코드는 `200/201/202/204` 혼재 |

## 현재 식별된 잔존 `PageResponse` 사용 지점
- [x] `lib/feature/terms/service/terms_request_service.dart`
- [x] `lib/common/base/api_response/page_response.dart`
- [x] 현 시점 Swagger 기준 일반 사용자 엔드포인트에서 `PageResponse` 직접 사용처는 사실상 제거 대상임을 확인

## 약관 기능 정리
- [x] `GET /api/terms`를 `ApiResponse<List<Terms...Dto>>` 구조로 수정
- [x] 약관 DTO 필드를 Swagger 기준으로 변경
- [x] `termDefinitionId` -> `id` 전환
- [x] `termsTypes` -> `type` 전환
- [x] `version` 타입을 실제 스펙에 맞게 조정
- [x] `content`, `effectiveDate`, `isRequired` 반영
- [x] 단건 약관 조회 관련 서비스 제거 또는 호출 차단
- [x] `TermsDetailView`, 라우트, 진입 경로 제거 범위 점검
- [x] 단일 약관 동의 관련 서비스 제거 또는 호출 차단
- [x] 약관 전체 동의 요청 body를 Swagger 기준으로 수정
- [x] `consents[].termDefinitionId` -> `consents[].id` 전환
- [x] 약관 화면/상태관리에서 단건 상세 이동 의존성 제거

## 내 정보 기능 정리
- [x] `GET /api/users/my` 응답 DTO를 Swagger 기준으로 수정
- [x] `userEmail`, `userNickname` 필드명 의존 제거
- [x] `id`, `email`, `nickname`, `oAuth2Provider` 반영
- [x] 닉네임 변경 API를 `POST`에서 `PATCH`로 수정
- [x] 닉네임 변경 request body를 `{ "nickname": ... }`로 수정
- [x] `my_info_view.dart` 및 관련 ViewModel 필드명 반영

## 사용자 검색 기능 정리
- [x] `GET /api/users`를 `ApiResponse<SliceResponse<UserSearchResponseDto>>`로 수정
- [x] `data.content` 기준 파싱으로 통일
- [x] 검색 DTO를 Swagger 필드명 기준으로 수정
- [x] `userId`, `userEmail`, `userNickname` 의존 제거
- [x] `id`, `email`, `nickname`, `oAuth2Provider` 반영
- [x] 검색 결과 UI와 친구 요청 진입부 필드명 반영

## 친구 요청 기능 정리
- [x] 목록 조회 시 `type=SENT|RECEIVED` 쿼리 반영
- [x] 친구 요청 목록 응답을 `ApiResponse<SliceResponse<...>>`로 수정
- [x] 친구 요청 상세/수락/거절 ID 타입을 `int`에서 `String UUID`로 통일
- [x] 생성 요청 body를 Swagger 기준으로 수정
- [x] `receiverId`, `receiverEmail` 중심 구조 재검토
- [x] `targetId`, `message` 기준으로 단순화
- [x] 요청/상세/수락/거절 DTO를 nested user 구조 기준으로 재작성
- [x] `requester`, `receiver` 객체 구조 반영
- [x] 받은 요청 목록/레코드 화면 필드 참조 수정

## 친구 관계 기능 정리
- [x] 친구 목록 응답을 `ApiResponse<SliceResponse<...>>`로 수정
- [x] DTO를 nested user 구조 기준으로 수정
- [x] `friendRelationshipId` 중심 필드 의존 제거 여부 검토
- [x] 필요 시 DTO 내부에서 호환성 getter 제공 여부 판단
- [x] 별명 수정 body를 `{ "alias": ... }`로 수정
- [x] path id와 body를 분리
- [x] 친구 삭제 성공 코드를 `204`까지 허용하도록 수정
- [x] 친구 차단 성공 응답을 `data: null` 기준으로 처리
- [x] 연락처/지오펜스 수신자 모델 영향 범위 반영

## 친구 제한 기능 정리
- [x] 제한 목록 응답을 `ApiResponse<SliceResponse<...>>`로 수정
- [x] 제한 삭제 ID 타입을 `String UUID`로 통일
- [x] 삭제 응답을 객체 파싱하지 않고 성공 여부 중심으로 처리
- [x] 제한 DTO를 nested user 구조 기준으로 수정
- [x] `restrictor`, `restricted`, `type`, `expiredAt` 반영
- [x] 차단 목록 화면/뷰모델 필드 참조 수정

## 알림 기능 정리
- [x] `/api/notifications` 요청 DTO를 Swagger 계약 기준으로 재작성
- [x] `/api/notifications/batch` 요청 DTO를 Swagger 계약 기준으로 재작성
- [x] `notificationMethod`, `targetId`, `targetIds`, `type`, `extraData` 구조 반영
- [x] FCM 전송 코드에서 `receiverEmail`, `body` 중심 구조 제거
- [x] SMS 전송 코드에서 기존 `requests[]` 구조 제거
- [x] 성공 코드를 `202 Accepted` 기준으로 처리
- [x] 알림 발송 실패 로그와 사용자 메시지 정리

## FCM 토큰 등록 정리
- [x] `/api/fcm-tokens` 성공 코드를 `201`까지 허용
- [x] 기존 `200` 고정 처리 제거
- [x] 성공/실패 로그 문구 정리

## 화면/상태관리 영향 범위 반영
- [x] ViewModel 시그니처 변경 반영
- [x] `int` 기반 ID를 `String`으로 통일
- [x] DTO 필드명 변경에 따른 UI 참조 수정
- [x] 약관 상세 라우트 제거 범위 반영
- [x] 삭제된 단건 동의/단건 조회 기능으로 이어지는 버튼, 이동, 상태 코드 제거

## 마일스톤

### Milestone 1. 공통 응답 기준 고정
- [x] Swagger 기준 엔드포인트별 응답 타입 표 확정
- [x] `ApiResponse`, `SliceResponse`, `PageResponse` 사용 원칙 확정
- [x] 공통 파싱 전략 문서화
- [x] `raw list`, `single object`, `slice`, `void` 공통 파서 추가
- [x] 테스트 추가로 공통 파서 동작 검증
- [x] 불필요한 `PageResponse` 사용 지점 식별 완료

### Milestone 2. 약관/내 정보 정렬
- [x] 약관 목록 API 파싱 수정
- [x] 단건 약관 조회 제거 반영
- [x] 단일 약관 동의 제거 반영
- [x] 전체 약관 동의 body 수정
- [x] 내 정보 조회 DTO 수정
- [x] 닉네임 변경 method/body 수정

### Milestone 3. 친구 도메인 정렬
- [x] 사용자 검색 slice 파싱 수정
- [x] 친구 요청 DTO/서비스 수정
- [x] 친구 관계 DTO/서비스 수정
- [x] 친구 제한 DTO/서비스 수정
- [x] UUID string 전환 완료

### Milestone 4. 알림 도메인 정렬
- [x] FCM 알림 payload 수정
- [x] SMS 단건 payload 수정
- [x] SMS 다건 payload 수정
- [x] `202` 성공 처리 반영
- [x] FCM 토큰 등록 `201` 처리 반영

### Milestone 5. 화면/상태관리 후속 반영
- [x] ViewModel 시그니처 수정
- [x] UI 필드 참조 수정
- [x] 삭제된 기능의 라우트/버튼/호출 제거
- [x] 지오펜스 수신자 모델 영향 반영

### Milestone 6. 검증
- [x] 약관 목록 조회 검증
- [x] 전체 약관 동의 검증
- [x] 내 정보 조회/닉네임 변경 검증
- [x] 사용자 검색 검증
- [x] 친구 요청 조회/수락/거절 검증
- [x] 친구 목록/별명 변경/삭제 검증
- [x] 차단 목록/차단 해제 검증
- [x] 알림 발송 검증
- [x] FCM 토큰 등록 검증

## 구현 원칙
- [x] 가능한 한 공통 응답 포맷 재사용
- [x] DTO 이름보다 Swagger 필드 계약을 우선
- [x] 중복 파싱 로직 축소
- [x] 화면단 보정보다 서비스/DTO 계층에서 정합성 확보
- [x] 제거된 기능은 임시 우회가 아니라 호출 경로 자체를 정리
