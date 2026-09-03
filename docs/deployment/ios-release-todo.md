# iOS 배포 — 운영자 TODO

저장소 쪽 iOS 설정은 끝났다. 아래는 **사람이 직접 해야 하는 것들**만 모은 목록이다.
빌드 절차 자체는 `docs/deployment/mobile-release.md` 의 iOS 섹션을 본다.

Windows 워크스테이션에서는 IPA를 만들 수 없다. 4번부터는 macOS + Xcode 필요.

---

## 1. Apple 계정 준비

- [ ] **Apple Developer Program 가입** (연 $99). 개인/법인 중 선택, 법인이면 D-U-N-S 번호 발급에 수 주 걸릴 수 있다.
- [ ] **App ID 등록** — Identifier `com.kdongsu5509.iamhere`, Capabilities 에서 **Push Notifications** 체크.
- [ ] **App Store Connect 앱 레코드 생성** — 이름, 기본 언어(한국어), 번들 ID, SKU.
- [ ] **팀 ID(10자리) 확인** — developer.apple.com > Membership, 또는 Xcode > Settings > Accounts.

## 2. APNs ↔ Firebase 연결

- [ ] developer.apple.com > Keys 에서 **APNs Auth Key(.p8)** 생성. 키 파일은 한 번만 다운로드된다 — 안전한 곳에 백업.
- [ ] Firebase 콘솔 > 프로젝트 설정 > **Cloud Messaging** > Apple 앱 구성에 `.p8` + Key ID + Team ID 업로드.
- [ ] 이거 안 하면 iOS 푸시가 아예 안 간다. 안드로이드는 영향 없음.

## 3. 저장소에 값 채우기

### `ios/Signing.xcconfig` (현재 3개 다 비어 있음)

| 키 | 값 | 어디서 |
| --- | --- | --- |
| `DEVELOPMENT_TEAM` | 10자리 팀 ID | 1번에서 확인한 값 |
| `GOOGLE_IOS_CLIENT_ID` | `...apps.googleusercontent.com` | Firebase 콘솔 > 프로젝트 설정 > iOS 앱 > `GoogleService-Info.plist` 다운로드 > `CLIENT_ID` |
| `GOOGLE_IOS_REVERSED_CLIENT_ID` | `com.googleusercontent.apps....` | 같은 파일의 `REVERSED_CLIENT_ID` |

비워두면: 아카이브 실패(팀 ID) / Google 로그인 콜백 실패(나머지 둘).

### Firebase Remote Config

- [ ] `ios_store_url` 을 실제 App Store 링크로 발행. 템플릿에는 자리표시자(`.../id0000000000`)만 들어 있다.
      iOS는 빌드 타임 폴백이 없어서, 값이 없으면 **강제 업데이트가 조용히 동작하지 않는다.**
- [ ] App Store id 는 앱 레코드 생성 후 App Store Connect URL 에서 확인 가능.

### 로컬 시크릿 `iam_here_flutter_secret.env`

- [ ] macOS 빌드 머신에도 이 파일을 옮겨 놓는다 (git 추적 안 됨, Flutter 에셋으로 번들됨).
- [ ] `FIREBASE_IOS_BUNDLE_ID` 가 `com.kdongsu5509.iamhere` 와 같은지 확인.

## 4. 외부 콘솔 등록

- [ ] **Kakao Developers** — 내 애플리케이션 > 플랫폼 > iOS 추가, 번들 ID `com.kdongsu5509.iamhere`.
      URL scheme(`kakao<네이티브앱키>`)은 이미 `Info.plist` 에 들어 있다.
- [ ] **Google Cloud Console** — OAuth 동의 화면이 게시(published) 상태인지 확인. iOS 클라이언트는 Firebase가 자동 생성한다.

## 5. macOS 빌드 머신

- [ ] Xcode 설치 후 `sudo xcode-select -s /Applications/Xcode.app`
- [ ] `sudo gem install cocoapods` (또는 Homebrew)
- [ ] Flutter SDK 설치, `flutter doctor` 통과
- [ ] 저장소 클론 + `iam_here_flutter_secret.env` 배치
- [ ] `bash scripts/ios_release_preflight.sh` 실행 — 위 값들이 다 채워졌는지 자동 검사한다.
- [ ] 첫 `pod install` 이 `ios/Podfile.lock` 을 새로 쓴다 (지금 커밋된 lock 은 구버전 플러그인 셋이라 Firebase pod 이 없다). **그 변경을 커밋할 것.**

## 6. 아카이브 & 업로드

- [ ] `pubspec.yaml` 의 `version:` 빌드 번호 확인. App Store Connect 는 같은 빌드 번호 재업로드를 거부한다.
- [ ] `flutter build ipa --release --dart-define-from-file=release-defines.json`
- [ ] Xcode Organizer 또는 Transporter 로 업로드.
- [ ] 첫 업로드 후 App Store Connect 에서 **TestFlight 내부 테스트** 그룹에 배포.

## 7. App Store Connect 제출 자료 (심사 전 필수)

- [ ] **스크린샷** — 6.7"(iPhone 15/16 Pro Max) 필수. 5.5" 는 선택. 시뮬레이터 캡처 가능.
- [ ] **앱 설명 / 키워드 / 프로모션 텍스트 / 지원 URL**
- [ ] **개인정보 처리방침 URL** — 웹 랜딩의 법적 문서 라우트를 그대로 쓴다.
- [ ] **App Privacy 설문** — `ios/Runner/PrivacyInfo.xcprivacy` 와 내용이 일치해야 한다:
      정밀 위치 / 이메일 주소 / 연락처, 전부 "앱 기능" 목적, 사용자 계정에 연결됨, 추적 없음.
- [ ] **연령 등급** 설문
- [ ] **수출 규정** — `ITSAppUsesNonExemptEncryption=false` 를 넣어 뒀으므로 업로드마다 묻지 않는다.

## 8. 심사 대응 준비 — 여기가 이 앱의 최대 리스크

이 앱은 **"항상 허용" 백그라운드 위치**를 쓴다. Apple 이 가장 깐깐하게 보는 항목이다.

- [ ] **심사 노트(App Review Notes)** 에 백그라운드 위치가 왜 핵심 기능인지 명시:
      "사용자가 등록한 장소에 도착/이탈할 때 지정한 친구에게 자동 알림을 보내는 것이 앱의 유일한 목적이며,
      앱이 종료된 상태에서도 감지해야 하므로 Always 권한이 필요하다."
- [ ] **데모 영상 또는 상세 재현 절차** 준비. 지오펜스는 심사자가 실제로 이동해야 확인되므로,
      영상 없이는 "기능을 확인할 수 없다"로 반려되기 쉽다.
- [ ] **데모 계정** 제공 (소셜 로그인만 있으므로, 심사자가 로그인할 수 있는 방법을 반드시 적어야 한다).
      카카오/구글 로그인만 지원한다면 이 부분을 심사 노트에 명확히 설명할 것.
- [ ] **연락처 권한** 사용 이유도 노트에 한 줄 추가 (알림 대상 친구 선택 용도).

## 9. TestFlight 스모크 테스트 (실기기 필수)

시뮬레이터로는 백그라운드 지오펜싱 검증 불가.

- [ ] 콜드 스타트
- [ ] 카카오 로그인
- [ ] Google 로그인
- [ ] 약관 동의 플로우
- [ ] 위치 권한 **항상 허용** 부여 → 장소 등록
- [ ] 앱을 백그라운드로 보낸 상태에서 도착 알림 수신
- [ ] SMS 발송
- [ ] `minimum_app_version` 을 올려서 강제 업데이트 화면 + `ios_store_url` 이동 확인
- [ ] 다크모드 / 라이트모드 전환 확인

---

## 지금 당장 나(Claude)한테 넘기면 되는 것

`ios/Signing.xcconfig` 의 세 값과 App Store id 를 알려주면 파일에 채워 넣는다.
