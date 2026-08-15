import { describe, expect, it } from "vitest";

import { getBrowserPreviewSession } from "./browser-preview-bridge";

describe("browser preview session", () => {
  it.each([
    ["/auth", false, null, false],
    ["/terms-consent", true, "pending", false],
    ["/terms-detail/1", true, "pending", false],
    ["/user-permission", true, "active", false],
    ["/geofence", true, "active", true],
  ] as const)(
    "keeps %s directly previewable",
    (path, authenticated, userStatus, autoSendReady) => {
      expect(getBrowserPreviewSession(path)).toEqual({
        auth: { authenticated, userStatus },
        autoSendReady,
      });
    },
  );
});
