import { describe, expect, it } from "vitest";

import { validateCloudFrontConfig } from "./validate-cloudfront-config.mjs";

const validDistribution = {
  CacheBehaviors: {
    Items: [
      {
        CachePolicyId: "release-cache",
        PathPattern: "/app/releases/*",
      },
      {
        CachePolicyId: "api-no-cache",
        OriginRequestPolicyId: "api-origin",
        PathPattern: "/api/*",
      },
    ],
  },
};

describe("validateCloudFrontConfig", () => {
  it("accepts immutable releases and uncached API forwarding", () => {
    expect(() =>
      validateCloudFrontConfig({
        apiCachePolicyId: "api-no-cache",
        apiOriginRequestPolicyId: "api-origin",
        distribution: validDistribution,
        releaseCachePolicyId: "release-cache",
      }),
    ).not.toThrow();
  });

  it("rejects an API behavior with the wrong cache policy", () => {
    expect(() =>
      validateCloudFrontConfig({
        apiCachePolicyId: "wrong-policy",
        apiOriginRequestPolicyId: "api-origin",
        distribution: validDistribution,
        releaseCachePolicyId: "release-cache",
      }),
    ).toThrow("API behavior does not use the no-cache policy");
  });
});
