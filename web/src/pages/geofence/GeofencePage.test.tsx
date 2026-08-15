import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

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

function envelope(data: unknown) {
  return new Response(
    JSON.stringify({ imhereResponseCode: "SUCCESS", message: "ok", data }),
    { status: 200 },
  );
}

function stubMapApi() {
  vi.stubGlobal(
    "fetch",
    vi.fn(async (input: RequestInfo | URL) => {
      if (String(input).includes("/api/maps/reverse-geocode")) {
        return envelope({
          results: [
            {
              name: "서울시청",
              region: {
                area1: { name: "서울특별시" },
                area2: { name: "중구" },
              },
              land: { name: "세종대로", number1: "110" },
            },
          ],
        });
      }
      return envelope({ content: [], hasNext: false });
    }),
  );
}

describe("GeofencePage", () => {
  afterEach(() => vi.unstubAllGlobals());

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

  it("lets device-recipient messages be edited but refuses input over the SMS limit", async () => {
    stubMapApi();
    const controller = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: true,
        locationAlways: true,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: [],
      }),
      getCurrentPosition: async () => ({
        latitude: 37.5665,
        longitude: 126.978,
        accuracy: 10,
        timestamp: new Date().toISOString(),
      }),
      getDeviceContacts: async () => [
        {
          id: "contact-1",
          displayName: "가족",
          phoneNumbers: ["010-1234-5678"],
        },
      ],
    });

    render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter initialEntries={["/geofence/message"]}>
          <Routes>
            <Route
              path="/geofence/message"
              element={<GeofencePage screen="message" />}
            />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    const placeName = await screen.findByLabelText("장소 이름");
    // 역지오코딩이 주소를 채운 뒤부터 사용자 입력을 흉내 낸다.
    await screen.findByDisplayValue("서울특별시 중구 세종대로 110");
    fireEvent.change(placeName, { target: { value: "회사" } });
    // 라벨 요소가 헬퍼 문구까지 감싸고 있어 부분 일치로 찾는다.
    const message = screen.getByLabelText(/^알림 메시지/);
    expect(message).toHaveValue("안녕하세요! 회사에 도착했습니다.");
    expect(message).not.toBeDisabled();

    // 기기 연락처를 골라도 메시지는 계속 편집할 수 있어야 한다.
    fireEvent.click(await screen.findByRole("checkbox", { name: /가족/ }));
    expect(message).not.toBeDisabled();

    // 머리말 9자를 더하면 정확히 45자. 여기까지는 들어간다.
    fireEvent.change(message, { target: { value: "가".repeat(36) } });
    expect(message).toHaveValue("가".repeat(36));

    // 한 글자 더는 입력 자체가 거부된다.
    fireEvent.change(message, { target: { value: "가".repeat(37) } });
    expect(message).toHaveValue("가".repeat(36));

    fireEvent.change(message, { target: { value: "{location} 도착" } });

    // 장소 이름도 {location} 치환을 거쳐 본문에 들어가므로 같은 한도를 받는다.
    fireEvent.change(placeName, { target: { value: "가".repeat(33) } });
    expect(placeName).toHaveValue("가".repeat(33));
    fireEvent.change(placeName, { target: { value: "가".repeat(34) } });
    expect(placeName).toHaveValue("가".repeat(33));

    fireEvent.submit(placeName.closest("form") as HTMLFormElement);
    await waitFor(() =>
      expect(
        controller.calls.some((call) => call.method === "registerGeofence"),
      ).toBe(true),
    );
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
