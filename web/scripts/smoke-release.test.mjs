import { describe, expect, it } from "vitest";

import { smokeRelease } from "./smoke-release.mjs";

const sha = "a".repeat(40);
const releaseUrl = `https://app.example.com/app/releases/${sha}/index.html`;
const cacheHeaders = {
  "cache-control": "public,max-age=31536000,immutable",
};

describe("smokeRelease", () => {
  it("checks the release index and every direct asset", async () => {
    const requested = [];
    const fetchImpl = async (input) => {
      const url = input.toString();
      requested.push(url);
      if (url === releaseUrl) {
        return new Response(
          '<div id="root"></div><script src="/app/releases/' +
            `${sha}/assets/app.js"></script>` +
            `<link href="/app/releases/${sha}/assets/app.css" rel="stylesheet">`,
          { headers: cacheHeaders },
        );
      }
      return new Response("asset", { headers: cacheHeaders });
    };

    await expect(
      smokeRelease({ releaseUrl, expectedSha: sha, fetchImpl }),
    ).resolves.toEqual({ assetCount: 2, releaseUrl });
    expect(requested).toHaveLength(3);
  });

  it("rejects assets outside the immutable release prefix", async () => {
    const fetchImpl = async () =>
      new Response(
        '<div id="root"></div><script src="/app/assets/app.js"></script>',
        { headers: cacheHeaders },
      );

    await expect(
      smokeRelease({ releaseUrl, expectedSha: sha, fetchImpl }),
    ).rejects.toThrow("escaped the immutable release prefix");
  });
});
