import { describe, expect, it } from "vitest";

import { normalizePushPath } from "./record-model";

describe("normalizePushPath", () => {
  it("removes the WebView basename from native push paths", () => {
    expect(normalizePushPath("/app/record/notifications/3")).toBe(
      "/record/notifications/3",
    );
  });

  it("rejects external and malformed navigation targets", () => {
    expect(normalizePushPath("https://attacker.example")).toBe("/record");
    expect(normalizePushPath("//attacker.example")).toBe("/record");
    expect(normalizePushPath("\\record")).toBe("/record");
  });
});
