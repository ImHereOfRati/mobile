import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter, Route, Routes } from "react-router-dom";
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
  repeatType: "none" as const,
  message: "회사에 도착했습니다.",
  active: true,
  awaitingDeparture: false,
  deviceContactIds: [],
  serverRecipients: [],
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
    expect(screen.getByText("500m 경계 진입·이탈 시")).toBeVisible();

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

  it("keeps edit and delete actions in a compact action sheet", async () => {
    renderList();
    fireEvent.click(await screen.findByRole("button", { name: "회사 더보기" }));
    expect(screen.getByRole("dialog", { name: "회사" })).toBeVisible();

    fireEvent.click(screen.getByRole("button", { name: "삭제" }));
    expect(
      screen.getByRole("dialog", { name: "알림 장소를 삭제할까요?" }),
    ).toBeVisible();
  });

  it("redirects to permission setup before loading the place form", async () => {
    const controller = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: ["locationAlways"],
      }),
    });

    render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter initialEntries={["/geofence/message"]}>
          <Routes>
            <Route
              path="/geofence/message"
              element={<GeofencePage screen="message" />}
            />
            <Route
              path="/auto-send-readiness"
              element={<p>permission-guide</p>}
            />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(await screen.findByText("permission-guide")).toBeVisible();
    expect(
      controller.calls.some((call) => call.method === "getCurrentPosition"),
    ).toBe(false);
  });
});
