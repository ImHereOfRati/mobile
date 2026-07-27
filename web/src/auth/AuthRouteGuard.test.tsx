import { createMockBridge } from "@imhere/bridge-contract";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { describe, expect, it } from "vitest";

import { BridgeContext } from "@/bridge/bridge-context";

import { NativeAuthRouteGuard } from "./AuthRouteGuard";

const ready = {
  ready: true,
  locationAlways: true,
  locationService: true,
  notification: true,
  batteryOptimization: true,
  missing: [],
};

function renderGuard(
  initialPath: string,
  auth: {
    authenticated: boolean;
    userStatus: "active" | "inactive" | "pending" | null;
  },
  autoSendReady = true,
) {
  const controller = createMockBridge({
    getAuthState: async () => auth,
    getAutoSendReadiness: async () => ({
      ...ready,
      ready: autoSendReady,
      missing: autoSendReady ? [] : ["locationAlways"],
    }),
  });

  render(
    <BridgeContext.Provider value={controller.bridge}>
      <MemoryRouter initialEntries={[initialPath]}>
        <Routes>
          <Route element={<NativeAuthRouteGuard />}>
            <Route path="/auth" element={<p>auth page</p>} />
            <Route path="/terms-consent" element={<p>terms page</p>} />
            <Route path="/user-permission" element={<p>permission page</p>} />
            <Route path="/record" element={<p>record page</p>} />
          </Route>
        </Routes>
      </MemoryRouter>
    </BridgeContext.Provider>,
  );
}

describe("NativeAuthRouteGuard", () => {
  it("loads native state and protects authenticated routes", async () => {
    renderGuard("/record", { authenticated: false, userStatus: null });

    expect(await screen.findByText("auth page")).toBeVisible();
  });

  it("preserves the pending-terms flow from the Flutter router", async () => {
    renderGuard("/record", { authenticated: false, userStatus: "pending" });

    expect(await screen.findByText("terms page")).toBeVisible();
  });

  it("allows an active and ready user to open the requested page", async () => {
    renderGuard("/record", { authenticated: true, userStatus: "active" });

    expect(await screen.findByText("record page")).toBeVisible();
  });
});
