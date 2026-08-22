import { createMockBridge } from "@imhere/bridge-contract";
import { act, render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";
import { ThemeProvider } from "@/design-system";

import SettingPage from "./SettingPage";

const envelope = (data: unknown) =>
  JSON.stringify({ imhereResponseCode: "SUCCESS", message: "ok", data });

afterEach(() => {
  vi.unstubAllGlobals();
  document.documentElement.removeAttribute("data-theme");
});

describe("SettingPage", () => {
  it("shows API account data and native app diagnostics accessibly", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async (input: RequestInfo | URL) => {
        const path = String(input);
        return new Response(
          envelope(
            path.includes("/api/users/my")
              ? {
                  id: "me",
                  email: "me@example.com",
                  nickname: "고동수",
                  oAuth2Provider: "KAKAO",
                }
              : [],
          ),
        );
      }),
    );
    const controller = createMockBridge({
      getAccessToken: async () => ({ accessToken: "token" }),
      getAppInfo: async () => ({
        appVersion: "2.0.0",
        buildNumber: "42",
        platform: "android",
        locale: "ko-KR",
        theme: "light",
      }),
      getAutoSendReadiness: async () => ({
        ready: true,
        locationAlways: true,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: [],
      }),
      queryRecords: async () => ({ items: [] }),
    });
    const { container } = render(
      <BridgeProvider bridge={controller.bridge}>
        <ThemeProvider>
          <MemoryRouter>
            <SettingPage />
          </MemoryRouter>
        </ThemeProvider>
      </BridgeProvider>,
    );

    expect(await screen.findByText("고동수")).toBeVisible();
    expect(screen.getByText("2.0.0 (42)")).toBeVisible();
    expect((await axe.run(container)).violations).toEqual([]);
  });

  it("follows native theme changes and synchronizes the status bar", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(
        async (input: RequestInfo | URL) =>
          new Response(
            envelope(
              String(input).includes("/api/users/my")
                ? {
                    id: "me",
                    email: "me@example.com",
                    nickname: "나",
                    oAuth2Provider: "KAKAO",
                  }
                : [],
            ),
          ),
      ),
    );
    const controller = createMockBridge({
      getAppInfo: async () => ({
        appVersion: "2.0.0",
        buildNumber: "42",
        platform: "android",
        locale: "ko-KR",
        theme: "light",
      }),
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: false,
        batteryOptimization: false,
        missing: ["locationAlways"],
      }),
      queryRecords: async () => ({ items: [] }),
    });
    render(
      <BridgeProvider bridge={controller.bridge}>
        <ThemeProvider>
          <MemoryRouter>
            <SettingPage />
          </MemoryRouter>
        </ThemeProvider>
      </BridgeProvider>,
    );

    await screen.findByText("2.0.0 (42)");
    const emitTheme = controller.emit as unknown as (
      event: "onThemeChanged",
      payload: { theme: "dark" },
    ) => void;
    act(() => emitTheme("onThemeChanged", { theme: "dark" }));
    await waitFor(() =>
      expect(document.documentElement.dataset.theme).toBe("dark"),
    );
    expect(
      controller.calls.some(
        (call) =>
          call.method === "setStatusBarStyle" &&
          (call.args[0] as { style: string }).style === "light",
      ),
    ).toBe(true);
  });

  it("opens app settings when always-on location permission needs setup", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(
        async (input: RequestInfo | URL) =>
          new Response(
            envelope(
              String(input).includes("/api/users/my")
                ? {
                    id: "me",
                    email: "me@example.com",
                    nickname: "nickname",
                    oAuth2Provider: "KAKAO",
                  }
                : [],
            ),
          ),
      ),
    );
    const controller = createMockBridge({
      getAppInfo: async () => ({
        appVersion: "2.0.0",
        buildNumber: "42",
        platform: "android",
        locale: "ko-KR",
        theme: "light",
      }),
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: true,
        batteryOptimization: true,
        missing: ["locationAlways"],
      }),
      queryRecords: async () => ({ items: [] }),
    });

    render(
      <BridgeProvider bridge={controller.bridge}>
        <ThemeProvider>
          <MemoryRouter>
            <SettingPage />
          </MemoryRouter>
        </ThemeProvider>
      </BridgeProvider>,
    );

    await screen.findByText("2.0.0 (42)");
    await act(async () => {
      screen.getByText("위치 권한 (항상 허용)").click();
    });

    expect(screen.getByText("내용을 확인했고 권한 설정 열기")).toBeVisible();
    expect(
      controller.calls.some((call) => call.method === "openAppSettings"),
    ).toBe(false);

    await act(async () => {
      screen.getByText("내용을 확인했고 권한 설정 열기").click();
    });

    expect(
      controller.calls.some((call) => call.method === "openAppSettings"),
    ).toBe(true);
    expect(
      controller.calls.some(
        (call) =>
          call.method === "requestPermission" &&
          (call.args[0] as { permission: string }).permission ===
            "locationAlways",
      ),
    ).toBe(false);
  });
});
