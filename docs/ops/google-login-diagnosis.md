# Google 로그인 실패 분석 및 SHA-1 검증

검증일: 2026-08-11

대상 앱:

- Android application ID: `com.kdongsu5509.iamhere`
- Firebase project: `imhere-53245`
- Firebase project number: `537442903618`
- Firebase Android App ID: `1:537442903618:android:2ba00f5f04c2d27115afdb`

## 결론

현재 디버그 APK의 SHA-1은 기존 운영 문서에 기록된 debug SHA-1과 다르다.

현재 디버그 APK:

```text
C2:48:2E:CA:A4:99:A0:3D:83:DF:E4:E2:EA:88:5C:5B:10:07:EF:9D
```

기존 문서에 기록된 debug SHA-1:

```text
7E:5B:C0:47:42:0B:A6:07:A2:CC:95:AF:47:24:12:CF:6C:4C:14:91
```

따라서 `flutter run` 또는 현재 debug APK에서 로그인 창이 뜨기 전
`DEVELOPER_ERROR`/`ApiException: 10`이 발생한다면 SHA-1 불일치가 가장
유력한 원인이다.

다만 Play Store 설치본은 debug 키가 아니라 Play App Signing 키를 사용한다.
빌드 종류별 인증서를 혼동하면 안 된다.

## CLI로 추출한 실제 값

### `signingReport`

실행 명령:

```powershell
cd C:\Project\ImHere\client\android
.\gradlew.bat signingReport
```

주요 결과:

```text
Variant: debug
Config: debug
Store: C:\ProgrammingEnvSetting\MyAndroidAVD\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: C2:48:2E:CA:A4:99:A0:3D:83:DF:E4:E2:EA:88:5C:5B:10:07:EF:9D
SHA-256: A3:BA:76:EA:47:DC:79:30:70:08:36:95:4F:94:A8:A0:32:03:31:6D:52:BA:EB:57:7C:A2:A3:64:31:D2:ED:FA

Variant: release
Config: release
Store: C:\Project\ImHere\client\android\keystore\imhere-upload.jks
Alias: imhere-upload
SHA1: 2F:A5:BF:FD:A2:56:E3:97:93:87:30:7E:BE:9D:7E:D7:68:75:5E:3D
SHA-256: C0:0A:A4:78:56:66:E0:EF:52:A3:B9:5E:9C:82:CD:85:DF:17:65:22:F2:8D:45:26:EA:3F:29:34:65:78:B5:28
```

### 실제 debug APK 인증서

실행 명령:

```powershell
$apksigner = Get-ChildItem `
  C:\ProgrammingEnvSetting\AndroidSDK\build-tools `
  -Recurse -Filter apksigner.bat |
  Sort-Object FullName |
  Select-Object -Last 1 -ExpandProperty FullName

& $apksigner verify --print-certs `
  C:\Project\ImHere\client\build\app\outputs\flutter-apk\app-debug.apk
```

결과:

```text
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-256 digest: a3ba76ea47dc7930700836954f94a8a03203316d52baeb577ca2a36431d2edfa
Signer #1 certificate SHA-1 digest: c2482ecaa499a03d83dfe4e2ea885c5b1007ef9d
Signer #1 certificate MD5 digest: 7bcad32dac1ad7292de8940bb2353ca0
```

콜론과 대소문자를 정규화하면 `signingReport`의 debug SHA-1과 동일하다.
즉, 현재 설치 대상 debug APK는 실제로 `C2:48:...:EF:9D` 인증서로 서명되어
있다.

### Firebase 설정 파일 및 앱 환경값

실행 명령:

```powershell
$json = Get-Content android/app/google-services.json -Raw | ConvertFrom-Json

Write-Output "application_id=$($json.client[0].client_info.android_client_info.package_name)"
Write-Output "firebase_project_id=$($json.project_info.project_id)"
Write-Output "firebase_project_number=$($json.project_info.project_number)"
Write-Output "mobilesdk_app_id=$($json.client[0].client_info.mobilesdk_app_id)"
Write-Output "oauth_client_count=$($json.client[0].oauth_client.Count)"
```

결과:

```text
application_id=com.kdongsu5509.iamhere
firebase_project_id=imhere-53245
firebase_project_number=537442903618
mobilesdk_app_id=1:537442903618:android:2ba00f5f04c2d27115afdb
oauth_client_count=0
other_platform_oauth_client_count=0
```

앱에 포함된 secret env의 Google server client ID:

```text
GOOGLE_SERVER_CLIENT_ID=537442903618-ei8sc64opm1ac3v60kjnv7u71m6jhm7v.apps.googleusercontent.com
```

백엔드 env 저장소의 값도 다음과 같이 확인된다.

```text
GOOGLE_CLIENT_ID_WEB=537442903618-ei8sc64opm1ac3v60kjnv7u71m6jhm7v.apps.googleusercontent.com
GOOGLE_CLIENT_ID_IOS=537442903618-mgpkfd7q78fgul5pbe4vk5fs7f8jtbtf.apps.googleusercontent.com
GOOGLE_CLIENT_ID_ANDROID=537442903618-fctkrpchh8o0jcjljp4658g9365nojku.apps.googleusercontent.com
```

현재 앱 코드는 `GOOGLE_SERVER_CLIENT_ID`를 `google_sign_in` 초기화에 직접
전달하므로 `google-services.json`의 `oauth_client`가 비어 있다는 사실만으로
실패 원인이라고 단정할 수는 없다. 그러나 OAuth client가 실제로 생성·등록되어
있는지 확인하고 `google-services.json`을 다시 내려받는 것이 안전하다.

## 빌드 종류별로 등록해야 하는 SHA-1

| 실행 대상 | 사용 인증서 | 등록해야 하는 SHA-1 |
|---|---|---|
| `flutter run`, debug APK | 현재 PC의 debug keystore | `C2:48:2E:CA:A4:99:A0:3D:83:DF:E4:E2:EA:88:5C:5B:10:07:EF:9D` |
| 로컬 signed release APK | upload keystore | `2F:A5:BF:FD:A2:56:E3:97:93:87:30:7E:BE:9D:7E:D7:68:75:5E:3D` |
| Play Store 설치 APK | Google Play App Signing certificate | `64:C9:84:E9:09:EA:1C:35:A4:C7:1A:0B:F5:28:B0:DA:4B:37:B4:2E` |

Play Store 설치본을 검증할 때는 로컬 upload SHA-1이 아니라 Play Console의
App signing certificate SHA-1을 사용해야 한다.

## SHA-1 검증 절차

### 1. 현재 설치 APK의 variant 확인

```powershell
cd C:\Project\ImHere\client
flutter build apk --debug
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

그 다음 APK 자체에서 인증서를 추출한다. `signingReport`와 APK 결과가 같아야
한다.

```powershell
$apksigner = Get-ChildItem `
  C:\ProgrammingEnvSetting\AndroidSDK\build-tools `
  -Recurse -Filter apksigner.bat |
  Sort-Object FullName |
  Select-Object -Last 1 -ExpandProperty FullName

& $apksigner verify --print-certs `
  build\app\outputs\flutter-apk\app-debug.apk
```

### 2. Firebase Console에서 비교

Firebase Console에서 다음 위치를 확인한다.

```text
Project: imhere-53245
Project settings
  -> Your apps
  -> Android app: com.kdongsu5509.iamhere
  -> SHA certificate fingerprints
```

현재 debug 테스트라면 최소한 다음 SHA-1이 등록되어 있어야 한다.

```text
C2:48:2E:CA:A4:99:A0:3D:83:DF:E4:E2:EA:88:5C:5B:10:07:EF:9D
```

등록 후 `google-services.json`을 다시 다운로드한다.

### 3. Google Cloud OAuth client에서 비교

Google Cloud Console의 `APIs & Services -> Credentials`에서 Android OAuth
client를 확인한다.

다음 조합이 정확히 일치해야 한다.

```text
Package name: com.kdongsu5509.iamhere
Certificate SHA-1: 설치된 APK의 실제 SHA-1
```

또한 Web OAuth client ID가 아래 세 위치에서 일치해야 한다.

```text
앱 GOOGLE_SERVER_CLIENT_ID
백엔드 GOOGLE_CLIENT_ID_WEB
Google Cloud Web OAuth client ID
```

### 4. 캐시를 제거하고 재설치

OAuth 인증서 등록 후 기존 앱 상태를 배제하기 위해 clean build와 앱 재설치를
실행한다.

```powershell
flutter clean
flutter pub get
adb uninstall com.kdongsu5509.iamhere
flutter run
```

## 런타임 로그로 원인 확정

디버그 빌드에서만 `AppLogger`가 Google 로그인 상세 오류를 출력한다.

```powershell
adb logcat -c
flutter run
```

별도 터미널에서 로그인 버튼을 누르면서 확인한다.

```powershell
adb logcat -v time |
  Select-String -Pattern `
    "Google sign-in|google_sign_in|GoogleSignIn|ApiException|DEVELOPER_ERROR|SignIn"
```

판정 기준:

| 로그 또는 현상 | 판단 |
|---|---|
| `ApiException: 10`, `DEVELOPER_ERROR` | package name/SHA-1/Android OAuth client 불일치 |
| 계정 선택창이 뜨기 전 실패 | Android OAuth 또는 SHA-1 설정 문제 가능성 높음 |
| `Google sign-in completed without an ID token` | server client ID 또는 OAuth client 문제 |
| `Google sign-in ID token received` 후 실패 | Google SDK는 성공했으며 백엔드 검증 단계 문제 |
| `AUTH-109` | nonce 불일치 |
| `AUTH-100` | ID token 만료 |
| `AUTH-102` | ID token 서명 검증 실패 |
| `AUTH-103` | ID token email claim 누락 |
| `OIDC_FORMAT_INVALID` 계열 | audience 또는 issuer 불일치 |

`Google sign-in ID token received` 로그가 보이면 SHA-1 문제일 가능성은 낮다.
그 이후 `/api/auth` 요청의 HTTP 상태와 서버 응답 코드, 서버 로그를 확인해야
한다.

## 백엔드 검증 포인트

백엔드는 Google ID token의 다음 값을 검증한다.

- issuer: `https://accounts.google.com` 또는 `accounts.google.com`
- audience: Web/iOS/Android OAuth client ID 목록 중 하나
- nonce: 앱이 생성한 nonce와 ID token의 nonce가 동일해야 함
- exp: 만료되지 않아야 함
- signature: Google 공개키로 검증 가능해야 함
- email: 필수 claim

특히 서버가 현재 배포 환경에서 아래 Web client ID를 실제로 허용하는지 확인한다.

```text
537442903618-ei8sc64opm1ac3v60kjnv7u71m6jhm7v.apps.googleusercontent.com
```

## 우선 처리 순서

1. 현재 debug SHA-1 `C2:48:...:EF:9D`를 Firebase Android 앱에 등록한다.
2. 같은 SHA-1과 package name으로 Google Cloud Android OAuth client가 있는지 확인한다.
3. `google-services.json`을 다시 다운로드한다.
4. clean/uninstall 후 debug APK로 재검증한다.
5. `ApiException: 10`인지, ID token 수신 후 `/api/auth`에서 실패하는지 로그로 분리한다.
6. ID token 수신 후 실패한다면 서버의 audience/nonce 설정과 실제 배포 env를 확인한다.

현재 증거만으로 가장 유력한 원인은 **현재 PC의 debug SHA-1
`C2:48:...:EF:9D`가 기존 등록값 `7E:5B:...:14:91`과 불일치하는 것**이다.
