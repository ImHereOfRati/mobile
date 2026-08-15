import { createMockBridge } from "@imhere/bridge-contract";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { describe, expect, it } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import AutoSendReadinessPage from "./AutoSendReadinessPage";

describe("AutoSendReadinessPage", () => {
  it("returns to place registration when setup is complete", async () => {
    const controller = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: true,
        locationAlways: true,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: [],
      }),
    });

    render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter
          initialEntries={[
            "/auto-send-readiness?returnTo=%2Fgeofence%2Fmessage",
          ]}
        >
          <Routes>
            <Route
              path="/auto-send-readiness"
              element={<AutoSendReadinessPage />}
            />
            <Route path="/geofence/message" element={<p>geofence-form</p>} />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(await screen.findByText("geofence-form")).toBeVisible();
  });
});
