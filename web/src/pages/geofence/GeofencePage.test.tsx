import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import GeofencePage from "./GeofencePage";

const geofence = {
  id: 7,
  name: "회사",
  address: "서울시 중구 세종대로",
  latitude: 37.5665,
  longitude: 126.978,
  radiusMeters: 500,
  eventType: "both" as const,
  repeatType: "weekday" as const,
  message: "회사에 도착했습니다.",
  active: true,
  awaitingDeparture: false,
  deviceContactIds: [],
  serverRecipients: [],
  createdAt: "2026-07-26T00:00:00Z",
  updatedAt: "2026-07-26T00:00:00Z",
};

function renderList() {
  const controller = createMockBridge({
    queryGeofences: async () => ({ items: [geofence] }),
    getAutoSendReadiness: async () => ({
      ready: true,
      locationAlways: true,
      locationService: true,
      notification: true,
      batteryOptimization: true,
      missing: [],
    }),
    getLocationServiceStatus: async () => ({ status: "enabled" }),
    setGeofenceActive: async (value) => ({
      ...geofence,
      active: (value as { active: boolean }).active,
    }),
  });
  const view = render(
    <BridgeProvider bridge={controller.bridge}>
      <MemoryRouter>
        <GeofencePage screen="list" />
      </MemoryRouter>
    </BridgeProvider>,
  );
  return { controller, ...view };
}

describe("GeofencePage", () => {
  it("renders native geofences and updates the active state through the bridge", async () => {
    const { controller } = renderList();
    expect(await screen.findByRole("heading", { name: "회사" })).toBeVisible();
    expect(screen.getByText("도착·출발 모두")).toBeVisible();

    fireEvent.click(screen.getByRole("checkbox"));
    await waitFor(() =>
      expect(
        controller.calls.some(
          (call) =>
            call.method === "setGeofenceActive" &&
            (call.args[0] as { active: boolean }).active === false,
        ),
      ).toBe(true),
    );
  });

  it("has no automated accessibility violations", async () => {
    const { container } = renderList();
    await screen.findByRole("heading", { name: "회사" });
    expect((await axe.run(container)).violations).toEqual([]);
  });
});
