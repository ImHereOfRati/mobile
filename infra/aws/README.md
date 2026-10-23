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

## 전환 이력 및 기존 리소스 정리

전환은 완료됐다 (두 도메인 모두 `E15GIB9OVWS7YR`에서 서빙, 스택은 `AttachAliases=true`).

옛 구성은 서버 저장소의 `infra/cloudformation/web-distribution.yml`이 관리하던 배포이며, 이제 쓰이지 않는다.
정리 대상은 다음과 같다.

| 옛 리소스 | 삭제 방법 |
|---|---|
| CloudFront `E2CXOALHV4E6I4` | 스택 `imhere-web-distribution` (ap-northeast-2) 삭제 |
| 캐시 정책 3종 | 스택 `imhere-web-cache-policies` (ap-northeast-2) 삭제 |
| CloudFront `E324SXCUS1EXU7` (디자인) | 비활성화 후 `delete-distribution` |
| 버킷 `imhere-web-prod`, `imhere-design-site-prod-747482682439` | 비운 뒤 삭제 |

삭제는 되돌릴 수 없다. 서버 저장소의 `web-distribution.yml`과 ADR-025도 이 구성을 가리키도록 갱신해야 한다.
