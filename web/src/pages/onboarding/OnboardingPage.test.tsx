import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import AuthPage from "./AuthPage";
import TermsConsentPage from "./TermsConsentPage";

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("onboarding screens", () => {
  it("shows all three auth steps and both native login choices", () => {
    render(
      <BridgeProvider bridge={createMockBridge().bridge}>
        <MemoryRouter>
          <AuthPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    fireEvent.click(screen.getByRole("button", { name: "다음" }));
    fireEvent.click(screen.getByRole("button", { name: "다음" }));
    expect(
      screen.getByRole("button", { name: "카카오로 계속하기" }),
    ).toBeVisible();
    expect(
      screen.getByRole("button", { name: "Google로 계속하기" }),
    ).toBeVisible();
  });

  it("has no automated accessibility violations on auth", async () => {
    const { container } = render(
      <BridgeProvider bridge={createMockBridge().bridge}>
        <MemoryRouter>
          <AuthPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    const result = await axe.run(container);
    expect(result.violations).toEqual([]);
  });

  it("automatically activates when there are no active terms", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            imhereResponseCode: "SUCCESS",
            message: "ok",
            data: [],
          }),
        ),
      )
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            imhereResponseCode: "SUCCESS",
            message: "ok",
            data: {},
          }),
        ),
      );
    vi.stubGlobal("fetch", fetchMock);
    const bridge = createMockBridge({
      getAccessToken: async () => ({
        accessToken: "access",
        expiresAt: null,
      }),
    }).bridge;

    render(
      <BridgeProvider bridge={bridge}>
        <MemoryRouter initialEntries={["/terms-consent"]}>
          <Routes>
            <Route path="/terms-consent" element={<TermsConsentPage />} />
            <Route path="/user-permission" element={<p>권한 화면</p>} />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2));
    expect(await screen.findByText("권한 화면")).toBeVisible();
    expect(JSON.parse(String(fetchMock.mock.calls[1]?.[1]?.body))).toEqual({
      consents: [],
    });
  });
});
