import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { LandingPage } from "./LandingPage";

vi.mock("@/landing/JourneyMap", () => ({
  JourneyMap: () => <div data-testid="journey-map" />,
}));

afterEach(() => {
  window.history.replaceState({}, "", "/");
  vi.unstubAllGlobals();
});

describe("LandingPage", () => {
  it("links the header documents to separate legal pages", () => {
    render(<LandingPage />);

    expect(
      screen.getByRole("link", { name: "개인정보처리방침" }),
    ).toHaveAttribute("href", "/privacy");
    expect(screen.getByRole("link", { name: "서비스 약관" })).toHaveAttribute(
      "href",
      "/terms",
    );
  });

  it("renders legal documents from the server response", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(
        async () =>
          new Response(
            JSON.stringify({
              data: [
                {
                  id: 1,
                  version: 2,
                  type: "PRIVACY",
                  title: "서버 개인정보처리방침",
                  content:
                    "1. 수집 항목\n- 이메일\n\n2. 이용 목적\n- 서비스 제공",
                  effectiveDate: "2026-06-29T00:00:00",
                  isRequired: true,
                },
              ],
            }),
            { status: 200, headers: { "Content-Type": "application/json" } },
          ),
      ),
    );
    window.history.replaceState({}, "", "/privacy");

    render(<LandingPage />);

    expect(
      await screen.findByRole("heading", { name: "서버 개인정보처리방침" }),
    ).toBeVisible();
    expect(screen.getByText("1. 수집 항목")).toBeVisible();
  });
});
