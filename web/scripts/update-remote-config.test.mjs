import { describe, expect, it } from "vitest";

import { updateRemoteConfig } from "./update-remote-config.mjs";

describe("updateRemoteConfig", () => {
  it("validates and publishes only web_app_url with the current ETag", async () => {
    const requests = [];
    const fetchImpl = async (input, init = {}) => {
      requests.push({ init, url: input.toString() });
      if (!init.method) {
        return Response.json(
          {
            parameters: {
              existing: { defaultValue: { value: "preserved" } },
            },
            version: { versionNumber: "7" },
          },
          { headers: { etag: '"current-etag"' } },
        );
      }
      return Response.json({}, { headers: { etag: '"published-etag"' } });
    };

    const result = await updateRemoteConfig({
      accessToken: "temporary-token",
      fetchImpl,
      projectId: "imhere-test",
      releaseUrl: "https://app.example.com/app/releases/abc/",
    });

    expect(result.etag).toBe('"published-etag"');
    expect(requests).toHaveLength(3);
    expect(requests[1].url).toContain("validate_only=true");
    expect(requests[2].url).not.toContain("validate_only");
    for (const request of requests.slice(1)) {
      expect(request.init.headers["If-Match"]).toBe('"current-etag"');
      const template = JSON.parse(request.init.body);
      expect(template.version).toBeUndefined();
      expect(template.parameters.existing.defaultValue.value).toBe("preserved");
      expect(template.parameters.web_app_url.defaultValue.value).toContain(
        "/app/releases/abc/",
      );
    }
  });

  it("does not publish when validation fails", async () => {
    const fetchImpl = async (_input, init = {}) => {
      if (!init.method) {
        return Response.json(
          { parameters: {} },
          { headers: { etag: '"etag"' } },
        );
      }
      return new Response("invalid template", { status: 400 });
    };

    await expect(
      updateRemoteConfig({
        accessToken: "temporary-token",
        fetchImpl,
        projectId: "imhere-test",
        releaseUrl: "https://app.example.com/app/releases/abc/",
      }),
    ).rejects.toThrow("Remote Config validation returned 400");
  });
});
