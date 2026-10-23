# AWS 정적 호스팅

버킷 하나(비공개) + CloudFront 하나로 세 사이트를 서빙한다.

| URL | 버킷 prefix | 원본 |
|---|---|---|
| `https://imhere.ratiko.co.kr/` | `landing/` | `landing_page` |
| `https://imhere.ratiko.co.kr/app/` | `app/` | `web` |
| `https://imhere-design.ratiko.co.kr/` | `design/` | `design_site` |

호스트/경로 → prefix 매핑은 `web-hosting.yml`의 CloudFront Function이 처리한다.
`/api/*`, `/swagger-ui/*`, `/docs/*`는 백엔드(`ApiOriginDomain`, 기본 `imhere-server.ratiko.co.kr`)로 프록시되며 캐시하지 않는다.
웹앱은 API를 같은 origin(`/api`)으로 호출한다.

## 최초 설정 (1회)

모든 AWS 리소스는 **us-east-1**에서 만든다 (CloudFront용 ACM 인증서 제약).

1. **GitHub OIDC 공급자**: IAM에 `token.actions.githubusercontent.com` 공급자가 없으면 추가한다
   (audience `sts.amazonaws.com`). 계정당 하나만 만들 수 있다.
2. **ACM 인증서**: `imhere.ratiko.co.kr`, `imhere-design.ratiko.co.kr` 두 도메인으로 DNS 검증 방식 요청.
   ACM이 보여주는 검증용 CNAME을 가비아 DNS에 등록하고 `발급됨`이 될 때까지 기다린다.
3. **스택 배포** (운영 중인 기존 CloudFront가 같은 도메인 별칭을 쓰고 있으므로 `AttachAliases=false`로 먼저 배포):
   ```bash
   aws cloudformation deploy \
     --region us-east-1 \
     --stack-name imhere-web \
     --template-file infra/aws/web-hosting.yml \
     --capabilities CAPABILITY_NAMED_IAM \
     --parameter-overrides \
       BucketName=<고유 버킷명> \
       CertificateArn=<ACM ARN> \
       GitHubOidcProviderArn=<OIDC provider ARN> \
       AttachAliases=false
   ```
4. **GitHub 설정**: Environment `production` 생성 후 Repository variables 등록
   (스택 출력과 대응).

   | Variable | 값 |
   |---|---|
   | `AWS_REGION` | `us-east-1` |
   | `AWS_DEPLOY_ROLE_ARN` | 출력 `DeployRoleArn` |
   | `WEB_BUCKET` | 출력 `BucketName` |
   | `CLOUDFRONT_DISTRIBUTION_ID` | 출력 `DistributionId` |
   | `VITE_GA_MEASUREMENT_ID`, `VITE_CLARITY_PROJECT_ID`, `VITE_NAVER_MAP_CLIENT_ID` | `web` 빌드용 |

## Android 릴리스 시크릿 (`app-cd.yml`)

| Secret | 내용 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | 업로드 키스토어(`base64 -w0`) |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | 키스토어 정보 |
| `FLUTTER_SECRET_ENV` | `iam_here_flutter_secret.env` 전체 내용 |
| `FIREBASE_OPTIONS_DART` | `lib/firebase_options.dart` 전체 내용 |
| `GOOGLE_SERVICES_JSON` | `android/app/google-services.json` 전체 내용 |

## 전환 및 기존 리소스 정리

기존 운영 리소스(계정 `747482682439`)는 새 스택이 준비될 때까지 건드리지 않는다.

| 기존 리소스 | 비고 |
|---|---|
| CloudFront `E2CXOALHV4E6I4` (`imhere.ratiko.co.kr`) | 버킷 `imhere-web-prod`, API는 `ratiko.co.kr` (도메인 변경 전 구성) |
| CloudFront `E324SXCUS1EXU7` (`imhere-design.ratiko.co.kr`) | 버킷 `imhere-design-site-prod-747482682439` |

1. 위 4단계(GitHub 변수)를 마치고 CD 세 개(`landing-page-cd`, `design-site-cd`, `web-cd`)를 수동 실행해 새 버킷을 채운다.
2. `https://<새 배포 도메인>/`, `/app/`, `/api/...`를 확인한다. 디자인 사이트는 `Host` 헤더가 필요하므로 별칭 이동 후 확인한다.
3. 별칭 이동: 기존 배포에서 별칭을 제거하거나 `aws cloudfront associate-alias`로 새 배포에 옮긴 뒤
   스택을 `AttachAliases=true`로 업데이트한다.
4. 가비아 CNAME(`imhere`, `imhere-design`)을 새 `DistributionDomainName`으로 바꾼다.
5. 정상 확인 후 기존 두 배포를 비활성화 → 삭제하고, 기존 두 버킷을 비운 뒤 삭제한다.
