# Notion 게시 워크플로

## 준비 상태
- 프로젝트에 Notion MCP 설정이 추가되어 있다: `opencode.json`
- 게시 대상 문서:
  - `docs/ai-records/background-delivery-plan.md`
  - `docs/ai-records/ui-transition-plan.md`

## 1. OpenCode 재시작
- `opencode.json` 변경은 실행 중 세션에 즉시 반영되지 않는다.
- OpenCode를 완전히 종료한 뒤 다시 실행한다.

## 2. Notion MCP 연결
- OpenCode 재시작 후 Notion MCP 연결 또는 인증 프롬프트가 나오면 진행한다.
- 연결할 Notion 페이지 또는 워크스페이스 접근 권한을 허용한다.
- 계획 문서를 넣을 상위 페이지를 하나 정해 둔다.

## 3. 게시 전에 정리할 문서 구조
- 문서 1: 백그라운드 실행 전략
- 문서 2: UI 전환 계획
- 권장 Notion 상위 구조:
  - `ImHere / 제품기획`
  - `ImHere / 기술설계`

## 4. 권장 게시 방식
- 문서를 하나의 큰 페이지로 합치지 말고 2개 페이지로 분리한다.
- 추천 페이지 제목:
  - `ImHere - 도착 자동 알림 백그라운드 실행 전략`
  - `ImHere - UI 전환 계획`

## 5. OpenCode에 요청할 문장 예시
- 아래처럼 요청하면 된다.

### 예시 1: 두 문서를 각각 새 페이지로 게시
```text
Notion MCP를 사용해서 다음 두 문서를 각각 새 페이지로 올려줘.

- docs/ai-records/background-delivery-plan.md
- docs/ai-records/ui-transition-plan.md

상위 페이지는 [여기에 Notion 페이지명 또는 링크] 아래로 해줘.
제목은 문서 성격에 맞게 정리해줘.
```

### 예시 2: 기존 페이지 아래 하위 페이지로 게시
```text
Notion MCP로 [기존 상위 페이지 링크] 아래에 하위 페이지 2개를 만들어줘.

1. 백그라운드 실행 전략
2. UI 전환 계획

본문은 각각 아래 파일 내용을 사용해줘.
- docs/ai-records/background-delivery-plan.md
- docs/ai-records/ui-transition-plan.md
```

### 예시 3: 게시 후 요약까지 추가
```text
Notion MCP로 두 계획 문서를 게시하고,
각 페이지 맨 위에 3줄 요약도 추가해줘.

파일:
- docs/ai-records/background-delivery-plan.md
- docs/ai-records/ui-transition-plan.md
```

## 6. 게시 후 확인 항목
- 페이지 제목이 의도대로 들어갔는지
- 본문 heading 구조가 유지되는지
- 코드 블록이나 리스트가 깨지지 않았는지
- 상위 페이지 위치가 맞는지
- 권한이 팀에 공유되어 있는지

## 7. 운영 원칙
- 기획 문서와 기술 문서는 분리 유지
- `지오펜스` 대신 사용자용 표현 `도착 자동 알림` 우선 사용
- Notion에 올린 뒤에도 원본은 repo의 `docs/ai-records/` 아래를 기준본으로 관리
