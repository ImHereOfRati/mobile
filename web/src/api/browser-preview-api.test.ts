import { describe, expect, it } from "vitest";

import { browserPreviewFetch } from "./browser-preview-api";

describe("browser preview API", () => {
  it("returns displayable friend and terms fixtures", async () => {
    const friendships = await browserPreviewFetch(
      "https://preview.invalid/api/friendships?page=0",
    );
    const terms = await browserPreviewFetch(
      "https://preview.invalid/api/terms?isActive=true",
    );

    expect(await friendships.json()).toMatchObject({
      data: { content: [{ friendAlias: "엄마" }] },
    });
    expect(await terms.json()).toMatchObject({
      data: [{ title: "서비스 이용약관" }],
    });
  });
});
