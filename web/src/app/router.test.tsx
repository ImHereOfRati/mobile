import { createMockBridge } from "@imhere/bridge-contract";
import { render, screen, within } from "@testing-library/react";
import { createMemoryRouter, RouterProvider } from "react-router-dom";

import { appRoutes } from "@/app/router";
import { BridgeProvider } from "@/bridge/BridgeProvider";

function renderRoute(path: string) {
  const router = createMemoryRouter(appRoutes, {
    basename: "/app",
    initialEntries: [path],
  });

  const bridge = createMockBridge(
    path === "/app/auth"
      ? {
          getAuthState: async () => ({
            authenticated: false,
            userStatus: null,
          }),
        }
      : {},
  ).bridge;

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
      await screen.findByRole("heading", {
        name: /위치를 기반으로\s+대신\s+연락을 보낼게요\./,
      }),
    ).toBeInTheDocument();
  });

  it("renders the four-tab shell on a main route", async () => {
    renderRoute("/app/geofence");
    const navigation = await screen.findByRole("navigation");
    expect(navigation).toBeVisible();
    expect(within(navigation).getAllByRole("link")).toHaveLength(5);
  });

  it("renders the not-found fallback for an unknown route", async () => {
    renderRoute("/app/unknown");
    expect(await screen.findByRole("heading")).toBeVisible();
  });
});
