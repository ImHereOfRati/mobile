import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";

export function validateCloudFrontConfig({
  distribution,
  releaseCachePolicyId,
  apiCachePolicyId,
  apiOriginRequestPolicyId,
}) {
  const behaviors = distribution.CacheBehaviors?.Items ?? [];
  const defaultBehavior = distribution.DefaultCacheBehavior;
  const release = behaviors.find(
    (behavior) => behavior.PathPattern === "/app/releases/*",
  );
  const api = behaviors.find((behavior) => behavior.PathPattern === "/api/*");

  if (!release) {
    throw new Error("CloudFront is missing /app/releases/* behavior.");
  }
  if (release.CachePolicyId !== releaseCachePolicyId) {
    throw new Error(
      "Release behavior does not use the immutable cache policy.",
    );
  }
  if (!api) throw new Error("CloudFront is missing /api/* behavior.");
  if (api.CachePolicyId !== apiCachePolicyId) {
    throw new Error("API behavior does not use the no-cache policy.");
  }
  if (api.OriginRequestPolicyId !== apiOriginRequestPolicyId) {
    throw new Error(
      "API behavior does not forward the required authorization and query data.",
    );
  }
  const hasSpaRewrite = (defaultBehavior?.FunctionAssociations?.Items ?? []).some(
    (association) => association.EventType === "viewer-request" &&
      typeof association.FunctionARN === "string" &&
      association.FunctionARN.length > 0,
  );
  if (!hasSpaRewrite) {
    throw new Error(
      "Default behavior is missing the viewer-request SPA rewrite function.",
    );
  }
}

if (
  process.argv[1] &&
  pathToFileURL(process.argv[1]).href === import.meta.url
) {
  const configPath = process.env.CLOUDFRONT_CONFIG_PATH?.trim();
  const releaseCachePolicyId = process.env.RELEASE_CACHE_POLICY_ID?.trim();
  const apiCachePolicyId = process.env.API_CACHE_POLICY_ID?.trim();
  const apiOriginRequestPolicyId =
    process.env.API_ORIGIN_REQUEST_POLICY_ID?.trim();
  if (
    !configPath ||
    !releaseCachePolicyId ||
    !apiCachePolicyId ||
    !apiOriginRequestPolicyId
  ) {
    throw new Error(
      "CLOUDFRONT_CONFIG_PATH and all three policy IDs are required.",
    );
  }

  const distribution = JSON.parse(await readFile(configPath, "utf8"));
  validateCloudFrontConfig({
    apiCachePolicyId,
    apiOriginRequestPolicyId,
    distribution,
    releaseCachePolicyId,
  });
  console.log("CloudFront release and API behaviors are configured correctly.");
}
