import { render, screen } from "@testing-library/react";
import { createMemoryRouter, RouterProvider } from "react-router-dom";

import { appRoutes } from "@/app/router";

function renderRoute(path: string) {
  const router = createMemoryRouter(appRoutes, {
    basename: "/app",
    initialEntries: [path],
  });

  return render(<RouterProvider router={router} />);
}

describe("app router", () => {
  it("renders the Korean auth placeholder", async () => {
    renderRoute("/app/auth");

    expect(
      await screen.findByRole("heading", {
        name: "로그인",
      }),
    ).toBeInTheDocument();
  });

  it("renders the four-tab shell on a main route", async () => {
    renderRoute("/app/geofence");

    expect(
      await screen.findByRole("heading", {
        name: "알림 장소",
      }),
    ).toBeInTheDocument();
    expect(screen.getByRole("navigation", { name: "주요 메뉴" })).toBeVisible();
    expect(screen.getByRole("link", { name: "장소" })).toBeVisible();
    expect(screen.getByRole("link", { name: "친구" })).toBeVisible();
    expect(screen.getByRole("link", { name: "기록" })).toBeVisible();
    expect(screen.getByRole("link", { name: "설정" })).toBeVisible();
  });

  it("renders the not-found fallback for an unknown route", async () => {
    renderRoute("/app/unknown");

    expect(
      await screen.findByRole("heading", {
        name: "페이지를 찾을 수 없습니다.",
      }),
    ).toBeInTheDocument();
  });
});
