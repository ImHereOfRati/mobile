import { fireEvent, render, screen } from "@testing-library/react";
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
  it("guides the user to each next selection in order", () => {
    render(<LandingPage />);

    expect(screen.getByText("수락하기를 눌러주세요")).toBeVisible();
    expect(
      screen.getByRole("link", { name: "지금 체험 시작하기" }),
    ).toHaveAttribute("href", "#experience");

    fireEvent.click(screen.getByRole("button", { name: "수락하기" }));
    expect(screen.getByText("알림 받을 장소를 선택하세요")).toBeVisible();

    fireEvent.click(screen.getByRole("radio", { name: "서울역" }));
    expect(screen.getByText("알림 받을 친구를 선택하세요")).toBeVisible();

    fireEvent.click(screen.getByRole("radio", { name: /철수/ }));
    expect(screen.getByText("설정을 저장해 다음 단계로 가세요")).toBeVisible();

    fireEvent.click(
      screen.getByRole("button", { name: "장소와 알림 대상 설정" }),
    );
    expect(screen.getByText("이동 시작을 눌러보세요")).toBeVisible();
  });

  it("links the header documents to separate legal pages", () => {
    render(<LandingPage />);

    expect(
      screen.getByRole("link", { name: "개인정보처리방침" }),
    ).toHaveAttribute("href", "/?document=privacy");
    expect(screen.getByRole("link", { name: "서비스 약관" })).toHaveAttribute(
      "href",
      "/?document=terms",
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
    window.history.replaceState({}, "", "/?document=privacy");

    render(<LandingPage />);

    expect(
      await screen.findByRole("heading", { name: "서버 개인정보처리방침" }),
    ).toBeVisible();
    expect(screen.getByText("1. 수집 항목")).toBeVisible();
  });
});
