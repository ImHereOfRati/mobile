import { describe, expect, it } from "vitest";

import { resolveAuthRedirect } from "./auth-redirect-policy";

const resolve = (
  authenticated: boolean,
  userStatus: "pending" | "active" | "inactive" | null,
  autoSendReady: boolean,
  requestedUrl: string,
) =>
  resolveAuthRedirect({
    auth: { authenticated, userStatus },
    autoSendReady,
    requestedUrl,
  });

describe("resolveAuthRedirect", () => {
  it("sends unauthenticated users to auth with redirect", () => {
    expect(resolve(false, null, false, "/record?tab=sent")).toBe(
      "/auth?redirect=%2Frecord%3Ftab%3Dsent",
    );
    expect(resolve(false, null, false, "/auth")).toBeNull();
  });

  it("sends pending users to terms consent", () => {
    expect(resolve(false, "pending", false, "/geofence")).toBe(
      "/terms-consent?redirect=%2Fgeofence",
    );
  });

  it("sends inactive users to auth with an inactive reason", () => {
    expect(resolve(false, "inactive", false, "/geofence")).toBe(
      "/auth?reason=inactive",
    );
  });

  it("guards active users until auto-send is ready, except guide routes", () => {
    expect(resolve(true, "active", false, "/record")).toBe(
      "/user-permission?redirect=%2Frecord",
    );
    expect(
      resolve(true, "active", false, "/location-permission-guide"),
    ).toBeNull();
  });

  it("returns ready users to a safe redirect or geofence", () => {
    expect(
      resolve(true, "active", true, "/user-permission?redirect=%2Frecord"),
    ).toBe("/record");
    expect(resolve(true, "active", true, "/auth")).toBe("/geofence");
  });
});
