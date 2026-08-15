# Web release deployment and rollback

The production React app is deployed as an immutable, commit-addressed release,
and the public landing page is synchronized to the bucket root:

`s3://<bucket>/app/releases/<40-character commit SHA>/index.html`

Flutter derives the Web shell URL as `<base_url>/app` from Firebase Remote
Config. Web deployment does not update the app URL or require an app release.
Immutable releases remain available for rollback and diagnostics.

The browser API origin is owned by the backend deployment. Set
`BACKEND_PUBLIC_ORIGIN` from `ImHereServer/docs/infra/cicd.md` (production:
`https://imhere.ratiko.co.kr`). The workflow passes it to the web build as
`VITE_API_BASE_URL`. The native shell reads the same backend address from
Firebase Remote Config's `base_url`; the web release workflow does not change
that backend parameter.

## One-time infrastructure setup

1. Deploy the policy stack:

   ```bash
   aws cloudformation deploy \
     --stack-name imhere-web-cache-policies \
     --template-file infra/aws/web-cache-policies.yml
   ```

2. Attach the stack outputs to the existing CloudFront distribution:

   - `/app/releases/*` → `ReleaseCachePolicyId`
   - `/api/*` → `ApiCachePolicyId` and `ApiOriginRequestPolicyId`

   The release behavior must point to the S3 app origin. The API behavior must
   point to the API origin. Put both behaviors ahead of broader patterns such
   as `/app/*` and the default behavior.

3. Create a GitHub OIDC IAM role for the `production` environment. Its trust
   policy must restrict the subject to:

   `repo:ImHereOfRati/mobile:environment:production`

   Grant only:

   - `s3:ListBucket` for the app prefixes;
   - `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` under
     `app/*` (including `app/releases/*` and the mutable `app/` root);
   - `cloudfront:GetDistributionConfig` for the production distribution.

   Do not create or store an AWS access key for Actions.

4. Configure Google Workload Identity Federation for GitHub Actions. Allow the
   production service account to read and publish Firebase Remote Config. Do
   not upload a service-account JSON key.

5. Add these GitHub `production` environment variables:

   | Variable                         | Value                                    |
   | -------------------------------- | ---------------------------------------- |
   | `AWS_DEPLOY_ROLE_ARN`            | GitHub OIDC deployment role ARN          |
   | `AWS_REGION`                     | S3 bucket region                         |
   | `WEB_APP_BUCKET`                 | S3 bucket name                           |
   | `WEB_CLOUDFRONT_DISTRIBUTION_ID` | Production distribution ID               |
   | `WEB_PUBLIC_ORIGIN`              | Public origin, without `/app`            |
   | `BACKEND_PUBLIC_ORIGIN`          | Backend origin from server CD docs       |
   | `RELEASE_CACHE_POLICY_ID`        | CloudFormation release policy output     |
   | `API_CACHE_POLICY_ID`            | CloudFormation API cache policy output   |
   | `API_ORIGIN_REQUEST_POLICY_ID`   | CloudFormation API origin policy output  |
   | `GCP_WORKLOAD_IDENTITY_PROVIDER` | Google WIF provider resource name        |
   | `GCP_SERVICE_ACCOUNT`            | Remote Config deployment service account |
   | `FIREBASE_PROJECT_ID`            | Firebase project ID                      |
   | `VITE_NAVER_MAP_CLIENT_ID`       | Public Naver Maps client ID              |
   | `VITE_GA_MEASUREMENT_ID`         | GA4 measurement ID                       |
   | `VITE_CLARITY_PROJECT_ID`        | Optional; omit when Clarity is not used  |

## Normal deployment

Merging a relevant change to `main` starts **Deploy immutable web app**. The
workflow:

1. builds with `/app/releases/<sha>/` as both Vite base and React Router
   basename;
2. obtains short-lived AWS credentials through GitHub OIDC;
3. uploads the build with a one-year immutable cache header;
4. verifies the deployed CloudFront behavior IDs;
5. fetches the index and its direct JS/CSS assets from the public URL;
6. obtains a short-lived Google access token through WIF;
7. leaves Remote Config unchanged. The client reads `base_url`, appends `/app`,
   and loads the mutable Web shell root.

If required environment variables are absent, the main-branch workflow records
a notice and skips deployment. It never falls back to long-lived credentials.

## Rollback

Use **Actions → Roll back web app → Run workflow** and enter a previously
verified lowercase 40-character commit SHA.

The workflow verifies that `index.html` still exists in S3, smoke-tests the old
public release, and then points `web_app_url` back to it. No upload, deletion,
or CloudFront invalidation is needed.

After rollback:

1. cold-start an Android and an iOS build;
2. verify authentication, geofence list, and one native bridge action;
3. confirm Firebase Remote Config shows the selected URL;
4. record the workflow run and result in the release task.

## Required rehearsal before launch

Perform one production-like rehearsal with release A and release B:

1. activate A;
2. deploy and activate B;
3. run the rollback workflow to A;
4. cold-start both platforms and confirm A loads;
5. re-activate B and confirm the forward path still works.

Old installed apps must also be checked against the final Remote Config and
minimum-version policy. Store rollout and force-update behavior remain human
release decisions.
