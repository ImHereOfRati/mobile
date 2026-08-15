import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen } from "@testing-library/react";
import { createMemoryRouter, RouterProvider } from "react-router-dom";

import { appRoutes } from "@/app/router";
import { BridgeProvider } from "@/bridge/BridgeProvider";

function renderRoute(path: string) {
  const router = createMemoryRouter(appRoutes, {
    basename: "/app",
    initialEntries: [path],
  });
  const onboarding = path === "/app/auth";
  const bridge = createMockBridge({
    getAuthState: async () =>
      onboarding
        ? { authenticated: false, userStatus: null }
        : { authenticated: true, userStatus: "active" },
    getAutoSendReadiness: async () => ({
      ready: !onboarding,
      locationAlways: !onboarding,
      locationService: true,
      notification: !onboarding,
      batteryOptimization: !onboarding,
      missing: onboarding
        ? ["locationAlways", "notification", "batteryOptimization"]
        : [],
    }),
  }).bridge;

  return render(
    <BridgeProvider bridge={bridge}>
      <RouterProvider router={router} />
    </BridgeProvider>,
  );
}

describe("app router", () => {
  it("renders the Korean auth onboarding", async () => {
    renderRoute("/app/auth");
    expect(
      await screen.findByRole(
        "heading",
        {
          name: /위치를 기반으로\s+대신\s+연락을 보낼게요\./,
        },
        { timeout: 5_000 },
      ),
    ).toBeInTheDocument();
  });

  it("renders main content without duplicating native navigation", async () => {
    renderRoute("/app/geofence");
    expect(
      await screen.findByRole("heading", { name: "알림 장소" }),
    ).toBeVisible();
    expect(screen.queryByRole("navigation")).not.toBeInTheDocument();
  });

  it("opens friend discovery in a bottom sheet and keeps the add deep link", async () => {
    const view = renderRoute("/app/friend");
    const openFinder = await screen.findByRole("button", {
      name: "새로운 친구 찾기",
    });
    expect(openFinder).toBeVisible();
    expect(screen.queryByRole("dialog", { name: "친구 찾기" })).toBeNull();

    fireEvent.click(openFinder);
    expect(screen.getByRole("dialog", { name: "친구 찾기" })).toBeVisible();
    expect(screen.getByPlaceholderText("닉네임 또는 이메일")).toBeVisible();
    expect(
      screen.queryByRole("textbox", { name: "요청 메시지" }),
    ).not.toBeInTheDocument();

    view.unmount();
    renderRoute("/app/friend/add");
    expect(
      await screen.findByPlaceholderText("닉네임 또는 이메일"),
    ).toBeVisible();
  });

  it("renders the not-found fallback for an unknown route", async () => {
    renderRoute("/app/unknown");
    expect(await screen.findByRole("heading")).toBeVisible();
  });
});
