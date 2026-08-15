# 외부 계정 이전 계획

기존 소유 계정의 외부 설정을 신규 계정으로 옮기고, Firebase는 `imhere-53245`
하나로 통합한다.

- 앱은 출시돼 있으나 실사용자가 없다. 다운타임·토큰 무효화·히스토리 소실을 감수한다.
- 자격 증명은 "전부 교체" 방침. 기존 보유자가 아는 값은 이전 가능 여부와 무관하게 새로 발급한다.
- **서버는 현재 전부 중단 상태다** (2026-08-04). 구 도메인을 유지할 이유가 없어 코드에서 완전히 제거했다.
- iOS는 미출시 — 관련 작업 전부 보류.

---

## 배포 전 남은 것 (2026-08-05 19:00 KST 예정)

순서대로 해야 한다. 1번이 안 되면 빌드 자체가 나오지 않는다.

- [x] **`build_runner` 재생성** (2026-08-04) — `lib/` 에러 **1381 → 263**개.
      `di_setup.config.dart`가 재생성되며 제거된 소스 참조가 정리됐다.

- [x] **잔존 Flutter UI 소스 정리** (2026-08-04) — 에러 **263 → 6개**,
      `build_runner`도 실패 없이 완료된다.

  `a6b698d feat: replace legacy Flutter UI with React shell`에서 UI는 React로
  넘겼는데 레거시 Flutter 화면 코드가 남아 pubspec에서 빠진 패키지
  (`flutter_riverpod`, `flutter_screenutil`, `flutter_naver_map`)를 import하고
  있었다.

  진입점(`main.dart` + `vm:entry-point` 4개)에서 도달 불가능하면서 컴파일도
  실패하는 파일 11개를 삭제했다. 도달 가능한 파일은 하나도 건드리지 않았다.
  삭제분은 대부분 git 미추적이라
  `scratchpad/legacy-ui-backup/`에 경로째 백업해 뒀다.

  부수 피해였던 것 2건은 되살렸다:
  - `fcm_notification_request_dto.dart` — UI 의존이 없는 직렬화 DTO. git에서 복원
  - `AppRoutes` → `AppPaths` — go_router 기반 라우팅은 폐기됐고
    `lib/shell/app_paths.dart`가 후속. `fcm_arrival_service.dart` 참조를 교체

- [ ] **남은 에러 6개 — 미커밋 리팩터링과 커밋된 코드의 불일치**

  레거시 UI와 무관하다. 작업 트리에 커밋되지 않은 geofence 리팩터링이 있고
  (`geofence_delivery_pipeline.dart` 228행, `geofence_entity.dart` 49행 등 10개
  파일), 그 변경이 커밋된 코드가 기대하는 것을 제거했다.

  | 위치 | 에러 | 원인 |
  | --- | --- | --- |
  | `di_setup.dart:52` | 위치 인자 9개 (8개 기대) | 미커밋 변경이 파이프라인에서 `AnalyticsReporter`를 제거했는데 `di_setup.dart`는 여전히 `FirebaseAnalyticsReporter()`를 넘긴다 |
  | `geofence_device_bridge_handlers.dart` 86·87·280·281 | `createdAt`/`updatedAt` 없음 | 미커밋 변경이 `GeofenceEntity`에서 두 필드를 제거했는데 브리지는 웹으로 내보내고 있다 |

  **결정 (2026-08-04): 리팩터링을 살리고 마저 완성한다.** `HEAD`로 되돌리는
  선택지는 버렸다 — 미커밋이라 되돌리면 복구할 수 없다.

  다음 세션에 할 일:

  - [ ] `di_setup.dart:52`에서 `FirebaseAnalyticsReporter()` 인자 제거.
        분석 이벤트를 계속 쓸 생각이면 파이프라인 쪽에 다시 넣을지 먼저 판단할 것 —
        미커밋 변경이 `_logAnalytics`와 `geofence_triggered`·`delivery_succeeded`·
        `delivery_failed` 이벤트를 통째로 들어냈다 (`48954a6 feat: add
        consent-gated analytics layer`로 들어온 계층이다)
  - [ ] `geofence_device_bridge_handlers.dart`에서 `createdAt`/`updatedAt` 제거
        (86·87행 생성부, 280·281행 직렬화부)
  - [ ] **React 셸 확인** — 위 두 필드가 웹 페이로드에서 사라진다. 웹이 이 값을
        읽고 있으면 함께 고쳐야 한다
  - [ ] 정리 후 `flutter analyze` 0 에러 확인, `flutter test` 통과 확인

  참고: 미커밋 변경은 geofence 계열 10개 파일에 걸쳐 있다
  (`git status --short lib/`). 커밋 전에 의도를 한 번 정리해 두는 편이 좋다.

- [x] **`lib/firebase_options.dart` 재생성** (2026-08-04) — Android 항목이
      `imhere-53245`로 바뀌었다.

  ```bash
  dart pub global activate flutterfire_cli   # 완료, /c/devtools/pub_cache/bin/
  flutterfire configure --project=imhere-53245 --platforms=android --yes
  ```

  > **iOS 항목은 아직 `imhere-96fd1`이다** (`firebase_options.dart:48-51`).
  > `--platforms=android`로 실행했으므로 iOS 블록은 구 값 그대로 남았다. iOS가
  > 미출시라 지금은 무해하지만, 12절에서 `imhere-96fd1`을 삭제하면 이 코드가
  > 존재하지 않는 프로젝트를 가리키게 된다. iOS 착수 시 함께 정리할 것.

- [ ] **업로드는 18:14 KST 이후** — 신규 업로드 키 유효 시각. 기준은 서명 시각이
      아니라 업로드 시각이다.

- [ ] **`imhere-upload.jks` + 비밀번호를 이 머신 밖에 백업** — 구 키를 이미
      삭제해 유일본이다. 잃으면 Play 재설정 요청을 처음부터 다시 해야 하고 그동안
      업로드가 막힌다.

---

## 검증된 값

전부 실제로 확인한 값이다. 추정치 없음.

### 업로드 키 (현행)

`android/keystore/imhere-upload.jks`, alias `imhere-upload`, PKCS12, RSA 4096,
2026-08-03 ~ 2056-07-26, SHA384withRSA.

```
MD5     D4:39:FA:44:8E:A5:12:68:88:40:1F:5D:4C:A4:83:81
SHA-1   2F:A5:BF:FD:A2:56:E3:97:93:87:30:7E:BE:9D:7E:D7:68:75:5E:3D
SHA-256 C0:0A:A4:78:56:66:E0:EF:52:A3:B9:5E:9C:82:CD:85:DF:17:65:22:F2:8D:45:26:EA:3F:29:34:65:78:B5:28
```

Play 통지 지문 = 로컬 PEM = `signingReport` release variant, **3중 일치 확인**.

### 구 업로드 키 — 전면 폐기

alias `dongsuKEY`. **2026-08-04에 관련된 것을 전부 제거했다.**

| 대상 | 처리 |
| --- | --- |
| `android/keystore/dongsuKey.jks` (개인 키) | 삭제 |
| `android/cert.der` (공개 인증서) | 삭제 |
| 지문·키 해시 기록 | 이 문서에서 삭제 |
| Firebase 등록 | 없었음 (등록된 적 없다) |

재추출 경로는 없다. 이 키로는 다시 서명할 수 없고, 그럴 필요도 없다.

Play Console의 "업로드 인증서" 지문이 2026-08-05 18:14 KST 이후
`2F:A5:BF:FD:…` (신규 키)로 바뀌는 것으로 재설정 반영을 확인한다. 구 지문과
대조할 필요는 없다.

### 앱 서명 인증서 (Google 보관)

Play가 스토어 배포본에 실제로 서명하는 키다. 개인 키는 Google이 갖고 있고 개발자는
공개 인증서만 받는다. Notion `ImHere 개발` 페이지 첨부
`deployment_cert (1).der`에서 추출했다.

subject·issuer 모두 `C=US, ST=California, L=Mountain View, O=Google Inc.,
OU=Android, CN=Android` — Google 생성분이 맞다. RSA 4096, SHA256withRSA,
2026-08-03 08:49:10 UTC ~ 2056-08-03.

```
SHA-1   64:C9:84:E9:09:EA:1C:35:A4:C7:1A:0B:F5:28:B0:DA:4B:37:B4:2E
SHA-256 99:23:62:22:42:2A:E7:94:E0:C4:0C:E8:E3:6E:CD:CD:5D:5A:B8:36:FA:B0:20:14:BD:45:45:18:7F:A9:98:0D
```

이 인증서의 생성 시각은 신규 업로드 키(08:59:38 UTC)보다 10분 앞선다. Notion에도
"업그레이드 일자 : 2026년 8월 3일"로 적혀 있어, 2026-08-03에 앱 서명 키 업그레이드가
이미 실행된 것으로 본다. 그렇다면 구 앱 서명 인증서가 따로 존재한다.

> **결정 (2026-08-04): 구 앱 서명 인증서는 등록하지 않는다.** API 28 미만 기기와
> 기존 설치본은 지원하지 않는다.
>
> 키 순환은 APK 서명 스킴 v3 기반이라 API 28+ 에만 새 키가 적용된다. 그 아래
> 기기는 구 앱 서명 키로 검증된 APK를 받으므로, 신규 인증서만 등록된 상태에서는
> 그 기기에서만 Google·Kakao 로그인이 실패한다.
>
> **`minSdk`를 24 → 28로 올려 이 구간을 없앴다** (`android/app/build.gradle.kts:52`).
> `flutter.minSdkVersion`(Flutter 3.38.6 기본값 24) 참조를 리터럴 28로 바꿨고,
> 이유를 주석으로 남겼다. 이제 지원 대상 전 기기가 신규 앱 서명 키를 쓴다.
>
> 대가: Android 7.0~8.1 (API 24~27) 기기는 스토어에서 앱을 받을 수 없다.

### 디버그 키

`~/.android/debug.keystore`. 2026-08-03 표준 파라미터로 재생성 (alias
`androiddebugkey`, 비밀번호 `android`, RSA 2048, 10000일). 이 머신의 모든 Android
프로젝트가 공유하므로 다른 프로젝트 디버그 SHA-1도 함께 바뀌었다.

```
SHA-1   7E:5B:C0:47:42:0B:A6:07:A2:CC:95:AF:47:24:12:CF:6C:4C:14:91
SHA-256 B9:52:FC:73:B1:7F:03:51:CA:15:14:48:D3:68:5C:D2:2D:16:DA:74:EB:2D:C6:07:9D:A2:0A:A3:A5:B6:95:34
```

### Kakao 키 해시 (base64)

Kakao 콘솔은 SHA-1이 아니라 이 형식을 요구한다.

```
신규 업로드 키 (imhere-upload) L6W//aJW45eThzB+vp1+12h1Xj0=
앱 서명 인증서 (Google)        ZMmE6QnqHDWkxxoL9Siw2ks3tC4=
debug (재생성)                flvAR0ILpgeizJWvRyQSz2xMFJE=
```

산출: `keytool -exportcert -alias <alias> -keystore <ks> -storepass <pw> | openssl sha1 -binary | openssl base64`

### Firebase 실측 (2026-08-04, CLI 15.25.1)

| 항목 | 값 |
| --- | --- |
| 로그인 계정 | `ratiko1517@gmail.com` |
| 접근 가능 프로젝트 | `imhere-53245` **하나뿐** (구 `imhere-96fd1`은 안 보임) |
| Android 앱 ID | `1:537442903618:android:2ba00f5f04c2d27115afdb` |
| iOS 앱 ID | `1:537442903618:ios:edcd4be1083a592c15afdb` (미출시인데 이미 등록됨) |
| 등록된 SHA | **6개** — 업로드 키·디버그·앱 서명 인증서 각 SHA-1/SHA-256. 미확인 지문 없음 |
| `oauth_client` | **0개** — SHA가 있어도 비어 있다 |
| Remote Config | 버전 1 게시 완료 (2026-08-04) |

### 계정

| 용도 | 계정 |
| --- | --- |
| Firebase / Google (신규) | `ratiko1517@gmail.com` |
| AWS 루트 | `ratioliver583@gmail.com` |
| DNS·DB (가비아) | `kod66170` 구글 계정 연동 — **구 계정, 이전 여부 확인 필요** |

### 도메인

공개 오리진은 `https://imhere.ratiko.co.kr` 하나. 뒤에서 단일 CloudFront 배포가
전부 처리한다.

| 경로 | 대상 |
| --- | --- |
| `/` | 랜딩 (React) |
| `/app/releases/<sha>/index.html` | 앱 번들, Flutter WebView가 로드 |
| `/api/*` | 백엔드 오리진 |

구 EC2 nginx는 `/api`·`/admin`·`/swagger-ui`·`/docs`·관리 경로만 유지하고 그 외
요청을 `https://imhere.ratiko.co.kr`로 301 전환한다 (server PR #111, 2026-07-26
머지 완료).

근거: Notion `ADR-025 도메인을 imhere.ratiko.co.kr 단일 출처로 통합`, 그리고
`FEAT-13 구현 계획 — React 랜딩 페이지 및 도메인 전환`. ADR-025 시점의 서버는
`ratiko.co.kr` 하나가 랜딩과 API를 같이 서빙하고 있었다
(`SERVER_NAME`·`CERT_DOMAIN` 모두 `ratiko.co.kr`).

---

## 1. Android 서명 키 (2절)

신규 업로드 키 유효 시각: **2026-08-05 09:14 UTC = 18:14 KST**. 기준은 서명
시각이 아니라 **업로드 시각**이다.

- [x] 디버그 keystore 재생성
- [x] 신규 업로드 키 `imhere-upload.jks` 생성
- [x] `upload_certificate.pem` 내보내기 (저장소 루트)
- [x] Play 업로드 키 재설정 요청 제출
- [x] 재설정 승인 통지 수신
- [x] `android/key.properties` 신규 키로 교체
- [x] `dongsuKey.jks` 삭제
- [x] 로컬 서명 검증 (`signingReport` 지문 일치)
- [ ] **18:14 KST 이후 내부 테스트 트랙 업로드 → Play 수락 확인**
- [ ] `upload_certificate.pem` 삭제
- [x] 앱 서명 키 업그레이드 — 2026-08-03 실행된 것으로 본다 (인증서 생성 시각과
      Notion 기록 일치)
- [ ] `imhere-upload.jks` + 비밀번호를 이 머신 밖에 백업

> `dongsuKey.jks`를 이미 지웠으므로 `imhere-upload.jks`가 **유일본**이다. 잃으면
> 재설정 요청을 다시 넣어야 하고 승인까지 업로드가 막힌다.

> 앱 서명 인증서는 구·신 두 개가 공존하지만 **신규 것만 등록한다** — API 28 미만
> 미지원 결정에 따른다. 위 "앱 서명 인증서" 절 참조.

## 2. Firebase (3절)

작업은 Firebase CLI로 한다.

```bash
APP=1:537442903618:android:2ba00f5f04c2d27115afdb
```

- [x] Android 앱 등록 + 신규 업로드 키 지문 등록 (이미 돼 있었음)
- [x] Remote Config 파라미터 게시 (`firebase deploy --only remoteconfig`)
- [x] 도메인 하드코딩 제거 — `lib/common/config/app_origin.dart` 신설
- [x] 디버그 키 SHA-1 · SHA-256 등록 (2026-08-04)
- [x] 앱 서명 인증서 SHA-1 · SHA-256 등록 (2026-08-04) — 현재 6개 등록됨
- [x] 구 앱 서명 인증서는 등록하지 않기로 결정 (2026-08-04) — API 28 미만 미지원
- [ ] GA4 속성 신규 생성 후 연결 (콘솔 전용, 웹용 `VITE_GA_MEASUREMENT_ID`와 별개)
- [ ] Crashlytics — 테스트 크래시 1회로 대시보드 활성화 (콘솔 전용)
- [x] `google-services.json` 재생성 (2026-08-04, `flutterfire configure`가 함께 처리)
- [x] `lib/firebase_options.dart` 재생성 (2026-08-04) — Android만. iOS 블록은 구 값 유지
- [ ] `oauth_client`가 0이 아닌지 확인 — **재생성 후에도 여전히 0개**다.
      4절(OAuth 동의 화면 + 웹 클라이언트)이 끝나야 채워진다
- [ ] GCP Workload Identity Pool + 배포용 서비스 계정 생성
- [ ] Android API 키에 패키지명 + 지문 제한

### Remote Config 파라미터

앱이 읽는 키는 5개다 (`lib/integration/firebase/firebase_remote_service.dart:7-11`).
`setDefaults()` 호출이 없어 누락이 에러 없이 폴백으로 흡수된다.

| 키 | 값 | 상태 |
| --- | --- | --- |
| `base_url` | `https://imhere.ratiko.co.kr` | 게시됨 |
| `web_app_url` | `https://imhere.ratiko.co.kr/app/releases/<sha>/index.html` — Remote Config 활성화 대기 | 미게시 |
| `minimum_app_version` | `2.0.0` | 게시됨 |
| `android_store_url` | `https://play.google.com/store/apps/details?id=com.kdongsu5509.iamhere` | 게시됨 |
| `ios_store_url` | 생성하지 않음 (iOS 미출시) | — |

`base_url`은 **오리진 루트**다. 엔드포인트가 `/api/...`로 시작하므로 `/api`를
붙이지 않는다.

`web_app_url`은 원래 CI가 `${WEB_PUBLIC_ORIGIN%/}/app/releases/<sha>/index.html` 형태의
불변 릴리스 URL로 덮어쓰는 값이었으나, 웹 배포가 재개될 때까지 **손으로 고정**한다
(2026-08-04 결정). 값은 코드의 빌드 폴백(`AppOrigin.webAppUrl`)과 같은
`https://imhere.ratiko.co.kr/app`이다.

> `deploy-web.yml:162`와 `rollback-web.yml:85`의 `update-remote-config.mjs`는
> 아직 살아 있다. **웹 배포를 한 번이라도 실행하면 이 고정값이 릴리스 URL로
> 덮어써진다.** 고정을 유지하려면 그 스텝을 제거하거나, 덮어써도 되는 시점까지
> 웹 배포를 돌리지 않아야 한다.

### 설정 반영 주기

`minimumFetchInterval`을 12시간 → **1시간**으로 줄였다
(`firebase_remote_service.dart:19`). 포그라운드 서비스와 백그라운드 isolate가
같은 상수를 참조하므로 두 경로가 갈리지 않는다. 디버그 빌드는 `Duration.zero`
그대로다.

Remote Config 백엔드가 앱 인스턴스당 대략 시간당 5회로 fetch를 조인다. 15분
아래로 내리면 `FirebaseRemoteConfigFetchThrottledException`을 만날 수 있어
1시간을 하한 여유로 잡았다.

```bash
firebase remoteconfig:get --project imhere-53245 -o remoteconfig.template.json
firebase deploy --only remoteconfig --project imhere-53245
firebase remoteconfig:rollback --version-number <N> --project imhere-53245
```

### CLI로 안 되는 것

GA4 연결, Crashlytics 활성화, OAuth 동의 화면, API 키 제한, APNs 키. 전부 콘솔.

## 3. Google 로그인 (4절)

- [ ] OAuth 동의 화면을 신규 계정 지원 이메일 기준으로 설정
- [ ] **웹** OAuth 클라이언트 생성 → `GOOGLE_SERVER_CLIENT_ID`
- [ ] 새 서버 client ID를 백엔드에 전달 (클라이언트·서버 동시 전환, 시점 합의 필요)

> `oauth_client`가 채워지려면 이 절이 2절의 설정 재생성보다 먼저 끝나야 한다.
> SHA 지문 등록만으로는 채워지지 않는다 — 실측으로 확인했다.

## 4. Kakao (5절)

- [ ] 신규 계정에 Kakao 앱 신규 생성
- [ ] Android 플랫폼: 패키지 `com.kdongsu5509.iamhere` + 키 해시 3개
      (업로드 키, 앱 서명 인증서 신규, 디버그). 구 앱 서명 인증서는 등록하지 않는다
- [ ] Web 플랫폼: `https://imhere.ratiko.co.kr`
- [ ] 새 네이티브 키를 **두 곳 모두**에 반영 —
      `iam_here_flutter_secret.env`, `android/local.properties`의 `kakao.native.app.key`
- [ ] Redirect URI를 새 키 기준으로 갱신 (`AndroidManifest.xml:78`의 `kakao${KEY}` 스킴)

## 5. Naver (6절)

- [ ] NCP Maps 애플리케이션 신규 생성 — 허용 호출자에 Android 패키지명 + `https://imhere.ratiko.co.kr`
- [ ] Naver 검색 애플리케이션 신규 등록 (계정 간 이전 불가)
- [ ] 신규 애플리케이션 검증 후 기존 것 삭제

## 6. AWS · DNS (7·8절)

- [ ] `infra/aws/web-cache-policies.yml` 배포 → 캐시 정책 ID 확보
- [ ] S3 버킷 + CloudFront 배포 생성
- [ ] GitHub OIDC 공급자 + 배포 역할 생성
- [ ] ACM 인증서를 **us-east-1**에서 DNS 검증으로 요청 (CloudFront는 이 리전만 읽는다)
- [ ] 가비아에 ACM 검증 CNAME 등록 — 호스트는 `ratiko.co.kr` 기준 상대 라벨, 값은 점으로 끝나게. **영구 보존** (갱신 때 재사용)
- [ ] 인증서를 CloudFront에 연결 + 대체 도메인 이름에 `imhere.ratiko.co.kr` 추가
- [ ] 가비아에 트래픽 CNAME 추가: 호스트 `imhere` → CloudFront 배포 도메인
- [ ] `dig +short imhere.ratiko.co.kr`이 CloudFront를 가리키는지 확인
- [ ] TTL 원복

> DNS는 가비아에 그대로 둔다. `imhere.ratiko.co.kr`은 apex가 아닌 서브도메인이라
> 평범한 CNAME이면 충분하고, Route 53을 쓰면 DNS 통제권이 이전 범위 밖 계정에
> 남는다.

> **가비아 계정이 `kod66170` 구글 계정에 연동돼 있다** (Notion 확인). 도메인
> 소유권 자체는 이전 범위 밖이지만, 이 계정 접근 권한이 없으면 위 레코드 작업을
> 못 한다. 착수 전에 확인할 것.

> FEAT-13에서 **DNS 레코드와 CloudFront 실제 변경은 명시적으로 제외 범위**였다.
> 코드·nginx 301은 병합됐지만 DNS는 아직 아무것도 바뀌지 않았다.

## 7. GitHub 설정 (9절)

- [ ] 저장소 변수 전량 교체 — `WEB_APP_BUCKET`, `WEB_CLOUDFRONT_DISTRIBUTION_ID`,
      `AWS_DEPLOY_ROLE_ARN`, `*_POLICY_ID`, `GCP_WORKLOAD_IDENTITY_PROVIDER`,
      `GCP_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`, `VITE_*`
- [ ] `WEB_PUBLIC_ORIGIN` = `https://imhere.ratiko.co.kr` (후행 슬래시 없이)

## 8. 검증 (11절)

- [ ] `flutter analyze`, `flutter test`
- [ ] 실기기 디버그: Kakao 로그인, Google 로그인, Naver 지도, Naver 검색
- [ ] FCM 테스트 메시지 수신 (포그라운드·백그라운드)
- [ ] Crashlytics 테스트 크래시 도착
- [ ] Remote Config 값 수신
- [ ] 릴리스 빌드로 위 항목 반복
- [ ] Play 내부 테스트 업로드 수락
- [ ] 웹 배포(`workflow_dispatch`) → `web_app_url` 자동 갱신 확인
- [ ] rollback-web 1회 실행

## 9. 기존 계정 정리 (12절)

전부 위 검증 통과 후에 한다.

- [ ] Firebase `imhere-96fd1` 삭제
- [ ] 구 NCP Maps · Naver 검색 애플리케이션 삭제
- [ ] 구 Kakao 앱 삭제
- [ ] 구 AWS 리소스 정리
- [ ] Play Console에서 기존 계정 권한 제거
- [ ] 구 업로드 키 사본 폐기 요청
- [ ] `imhere-53245`·GCP에서 기존 계정 Owner/Editor 바인딩 제거

---

## iOS / Apple — 전체 보류

미출시다. App Store 등록 빌드 없고 `ios/Runner/GoogleService-Info.plist`도 없다.
Firebase iOS 앱(`iamhere-ios`)만 이미 만들어져 있는데 아무것도 참조하지 않는다.

출시 착수 시 실행할 것:

- [ ] APNs 인증 키(.p8) 업로드
- [ ] `GoogleService-Info.plist` 생성 후 **Xcode 타겟에 포함** (파일만 두면 안 읽힌다)
- [ ] `ios/Runner/Info.plist` URL 스킴 (Google reversed client ID, Kakao)
- [ ] iOS API 키 번들 ID 제한
- [ ] Kakao iOS 플랫폼 등록
- [ ] Naver Maps 허용 호출자에 번들 ID 추가
- [ ] Remote Config `ios_store_url` 추가
- [ ] Apple Developer 팀 보유 계정 확인 — APNs 키·서명 인증서·프로비저닝 프로파일이 같은 팀에 묶인다

`flutterfire configure`에 `--platforms=android`를 명시해야 iOS 설정이 딸려오지 않는다.

---

## 저장소 변경

| 파일 | 상태 |
| --- | --- |
| `android/key.properties` | 신규 키로 교체 완료 |
| `android/keystore/imhere-upload.jks` | 유일본, gitignore 대상 |
| `firebase.json` | 신규. **`.gitignore:79`에 걸려 추적 안 됨** — 다른 머신·CI에서 재생성 필요 |
| `remoteconfig.template.json` | 신규, 비밀값 없음, 커밋 권장 |
| `lib/common/config/app_origin.dart` | 신규. 도메인 단일 출처 |
| `lib/main.dart`, `geofence_background_runtime.dart`, `web_url_resolver.dart` | 하드코딩 호스트 → `AppOrigin` |
| `README.md` | Swagger 링크 도메인 교체 |
| `android/app/build.gradle.kts` | `minSdk` 24 → **28** (앱 서명 키 순환 요건) |
| `android/cert.der` | 삭제 (구 업로드 키 공개 인증서) |
| `lib/firebase_options.dart` | Android → `imhere-53245` 재생성. **iOS 블록은 아직 `imhere-96fd1`** |
| `android/app/google-services.json` | 재생성 완료. `oauth_client`는 여전히 0개 |
| `firebase.json` | `flutterfire configure`가 flutter 항목 병합 — `remoteconfig` 설정은 보존됨 |
| `lib/**` 생성 파일 | `build_runner` 재생성 (59 outputs) |

도메인을 또 바꿀 때 손댈 곳은 `app_origin.dart`의 `defaultValue`와 Remote Config
`base_url` 둘뿐이다.

---

## 미결

- 백엔드가 `GOOGLE_SERVER_CLIENT_ID`로 ID 토큰을 검증하는가? 그렇다면 백엔드 저장소와 전환 일정을 맞춰야 한다.
- `/api/*` CloudFront 비헤이비어가 가리킬 백엔드 오리진은 어디인가? 서버가 중단 상태라 아직 대상이 없다.
- 가비아 계정(`kod66170` 연동) 접근 권한 확보 여부.

## Notion

- [x] `개인 플젝 : ImHere` — Remote Config 값을 `https://ratiko.co.kr` →
      `https://imhere.ratiko.co.kr`로 정정 (2026-08-04)
- [ ] **Notion 워크스페이스 접근 권한이 이전 대상 계정과 겹치는지 점검**

`ImHere 개발` 페이지에 업로드 키 비밀번호가 평문으로 있다. 현재 유일한 머신 밖
사본이므로 **의도적으로 유지한다** (2026-08-04 결정). 지우면 로컬
`android/key.properties`가 유일본이 되고, 그 파일을 잃으면 keystore를 열 수 없어
Play 업로드 키 재설정을 처음부터 다시 해야 한다.

다만 이번 이전의 "기존 보유자가 아는 값은 전부 교체" 방침과는 어긋나는 상태다.
구 업로드 키를 폐기한 이유가 값 노출이었는데 신규 키 비밀번호도 같은 곳에 평문으로
있다. 위 접근 권한 점검에서 기존 계정이 이 페이지를 볼 수 있다면 신규 키의 의미가
없어진다 — 그 경우 키를 다시 만들어야 한다.

해소 경로는 비밀번호를 전용 보관처(비밀번호 관리자 등)로 옮기고 Notion에는
포인터만 남기는 것이다. 1절의 "머신 밖 백업" 항목과 함께 처리하면 된다.
