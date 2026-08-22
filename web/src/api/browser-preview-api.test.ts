import { describe, expect, it } from "vitest";

import { browserPreviewFetch } from "./browser-preview-api";

describe("browser preview API", () => {
  it("returns the friend preview fixture", async () => {
    const response = await browserPreviewFetch(
      "https://preview.invalid/api/friendships?page=0",
    );

    expect(await response.json()).toMatchObject({
      data: { content: expect.any(Array) },
    });
  });
});
