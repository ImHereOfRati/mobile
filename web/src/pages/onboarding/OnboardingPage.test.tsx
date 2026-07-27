import { createMockBridge } from "@imhere/bridge-contract";
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import axe from "axe-core";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import AuthPage from "./AuthPage";
import PermissionGuidePage from "./PermissionGuidePage";
import PermissionPage from "./PermissionPage";
import TermDetailPage from "./TermDetailPage";
import TermsConsentPage from "./TermsConsentPage";

afterEach(() => {
  vi.unstubAllGlobals();
});

const activeTerm = {
  id: 1,
  type: "SERVICE",
  title: "서비스 이용약관",
  content: "약관 내용",
  version: 1,
  isRequired: true,
  effectiveDate: "2026-07-27",
};

const optionalTerm = {
  ...activeTerm,
  id: 2,
  type: "MARKETING",
  title: "마케팅 정보 수신",
  isRequired: false,
};

function envelopeResponse(data: unknown) {
  return new Response(
    JSON.stringify({
      imhereResponseCode: "SUCCESS",
      message: "ok",
      data,
    }),
  );
}

function mockTerms(terms = [activeTerm]) {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(envelopeResponse(terms)));
}

function bridgeWithAccessToken() {
  return createMockBridge({
    getAccessToken: async () => ({
      accessToken: "access",
      expiresAt: null,
    }),
  }).bridge;
}

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

  it.each([
    {
      button: "카카오로 계속하기",
      method: "signInWithKakao",
      status: "pending",
      destination: "약관 화면",
    },
    {
      button: "Google로 계속하기",
      method: "signInWithGoogle",
      status: "active",
      destination: "권한 화면",
    },
  ] as const)(
    "uses the native bridge when continuing with $button",
    async ({ button, method, status, destination }) => {
      const user = userEvent.setup();
      const session = {
        authState: { authenticated: true, userStatus: status },
        token: { accessToken: "access", expiresAt: null },
      };
      const controller = createMockBridge({
        [method]: async () => session,
      });
      render(
        <BridgeProvider bridge={controller.bridge}>
          <MemoryRouter initialEntries={["/auth"]}>
            <Routes>
              <Route path="/auth" element={<AuthPage />} />
              <Route path="/terms-consent" element={<p>약관 화면</p>} />
              <Route path="/user-permission" element={<p>권한 화면</p>} />
            </Routes>
          </MemoryRouter>
        </BridgeProvider>,
      );

      await user.click(screen.getByRole("button", { name: "다음" }));
      await user.click(screen.getByRole("button", { name: "다음" }));
      await user.click(screen.getByRole("button", { name: button }));

      expect(await screen.findByText(destination)).toBeVisible();
      expect(controller.calls).toContainEqual({ method, args: [] });
    },
  );

  it("shows the inactive-account recovery message from the route reason", () => {
    render(
      <BridgeProvider bridge={createMockBridge().bridge}>
        <MemoryRouter initialEntries={["/auth?reason=inactive"]}>
          <AuthPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(screen.getByRole("alert")).toHaveTextContent(
      "비활성화된 계정입니다. 도움이 필요하면 고객센터에 문의해 주세요.",
    );
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

  it("has no automated accessibility violations on terms consent", async () => {
    mockTerms();
    const { container } = render(
      <BridgeProvider bridge={bridgeWithAccessToken()}>
        <MemoryRouter>
          <TermsConsentPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(
      await screen.findByRole("checkbox", { name: /서비스 이용약관/ }),
    ).toBeVisible();
    const result = await axe.run(container);
    expect(result.violations).toEqual([]);
  });

  it("submits required and optional term choices after all-agree is adjusted", async () => {
    const user = userEvent.setup();
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(envelopeResponse([activeTerm, optionalTerm]));
    const activateWithTerms = vi.fn().mockResolvedValue({
      authState: { authenticated: true, userStatus: "active" },
      token: { accessToken: "active-access", expiresAt: null },
    });
    vi.stubGlobal("fetch", fetchMock);
    render(
      <BridgeProvider
        bridge={
          createMockBridge({
            getAccessToken: async () => ({
              accessToken: "access",
              expiresAt: null,
            }),
            activateWithTerms,
          }).bridge
        }
      >
        <MemoryRouter initialEntries={["/terms-consent"]}>
          <Routes>
            <Route path="/terms-consent" element={<TermsConsentPage />} />
            <Route path="/user-permission" element={<p>권한 화면</p>} />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    const all = await screen.findByRole("checkbox", { name: "전체 동의" });
    const required = screen.getByRole("checkbox", {
      name: /서비스 이용약관/,
    });
    const optional = screen.getByRole("checkbox", {
      name: /마케팅 정보 수신/,
    });
    const submit = screen.getByRole("button", {
      name: "동의하고 계속하기",
    });

    expect(submit).toBeDisabled();
    await user.click(all);
    expect(required).toBeChecked();
    expect(optional).toBeChecked();
    await user.click(optional);
    expect(required).toBeChecked();
    expect(optional).not.toBeChecked();
    expect(submit).toBeEnabled();
    expect(screen.getAllByRole("link", { name: "보기" })[0]).toHaveAttribute(
      "href",
      "/terms-detail/1",
    );

    await user.click(submit);

    expect(await screen.findByText("권한 화면")).toBeVisible();
    expect(activateWithTerms).toHaveBeenCalledWith({
      consents: [
        { id: 1, agreed: true },
        { id: 2, agreed: false },
      ],
    });
  });

  it("has no automated accessibility violations on term detail", async () => {
    mockTerms();
    const { container } = render(
      <BridgeProvider bridge={bridgeWithAccessToken()}>
        <MemoryRouter initialEntries={["/terms-detail/1"]}>
          <Routes>
            <Route path="/terms-detail/:termId" element={<TermDetailPage />} />
          </Routes>
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(
      await screen.findByRole("heading", { name: "서비스 이용약관" }),
    ).toBeVisible();
    const result = await axe.run(container);
    expect(result.violations).toEqual([]);
  });

  it("has no automated accessibility violations on permission readiness", async () => {
    const bridge = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: false,
        batteryOptimization: false,
        missing: ["locationAlways", "notification", "batteryOptimization"],
      }),
    }).bridge;
    const { container } = render(
      <BridgeProvider bridge={bridge}>
        <MemoryRouter>
          <PermissionPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(await screen.findByText("항상 위치 허용")).toBeVisible();
    const result = await axe.run(container);
    expect(result.violations).toEqual([]);
  });

  it("requests a missing permission through the native bridge and refreshes", async () => {
    const user = userEvent.setup();
    const controller = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: false,
        batteryOptimization: false,
        missing: ["locationAlways", "notification", "batteryOptimization"],
      }),
      requestPermission: async () => ({
        permission: "locationAlways",
        status: "granted",
      }),
    });
    render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter>
          <PermissionPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    const locationTitle = await screen.findByText("항상 위치 허용");
    const locationItem = locationTitle.closest("article");
    expect(locationItem).not.toBeNull();
    await user.click(
      within(locationItem as HTMLElement).getByRole("button", {
        name: "설정",
      }),
    );

    await waitFor(() =>
      expect(
        controller.calls.filter(
          ({ method }) => method === "getAutoSendReadiness",
        ),
      ).toHaveLength(2),
    );
    expect(controller.calls).toContainEqual({
      method: "requestPermission",
      args: [{ permission: "locationAlways" }],
    });
  });

  it("keeps permission recovery available when the native request fails", async () => {
    const user = userEvent.setup();
    const controller = createMockBridge({
      getAutoSendReadiness: async () => ({
        ready: false,
        locationAlways: false,
        locationService: true,
        notification: false,
        batteryOptimization: false,
        missing: ["locationAlways"],
      }),
      requestPermission: async () => {
        throw new Error("native request failed");
      },
    });
    render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter>
          <PermissionPage />
        </MemoryRouter>
      </BridgeProvider>,
    );

    const locationTitle = await screen.findByText("항상 위치 허용");
    const locationItem = locationTitle.closest("article");
    const settings = within(locationItem as HTMLElement).getByRole("button", {
      name: "설정",
    });
    await user.click(settings);

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "권한을 요청하지 못했습니다. 잠시 후 다시 시도해 주세요.",
    );
    expect(settings).toBeEnabled();
  });

  it.each(["location", "battery"] as const)(
    "has no automated accessibility violations on the %s permission guide",
    async (kind) => {
      const { container } = render(
        <BridgeProvider bridge={createMockBridge().bridge}>
          <MemoryRouter>
            <PermissionGuidePage kind={kind} />
          </MemoryRouter>
        </BridgeProvider>,
      );

      const result = await axe.run(container);
      expect(result.violations).toEqual([]);
    },
  );

  it("shows recovery feedback when system settings cannot be opened", async () => {
    const user = userEvent.setup();
    const bridge = createMockBridge({
      requestPermission: async () => {
        throw new Error("settings unavailable");
      },
    }).bridge;
    render(
      <BridgeProvider bridge={bridge}>
        <MemoryRouter>
          <PermissionGuidePage kind="location" />
        </MemoryRouter>
      </BridgeProvider>,
    );

    await user.click(screen.getByRole("button", { name: "설정 열기" }));

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "시스템 설정을 열지 못했습니다. 잠시 후 다시 시도해 주세요.",
    );
    expect(screen.getByRole("button", { name: "설정 열기" })).toBeEnabled();
  });

  it("automatically activates when there are no active terms", async () => {
    const fetchMock = vi.fn().mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          imhereResponseCode: "SUCCESS",
          message: "ok",
          data: [],
        }),
      ),
    );
    const activateWithTerms = vi.fn().mockResolvedValue({
      authState: { authenticated: true, userStatus: "active" },
      token: { accessToken: "active-access", expiresAt: null },
    });
    vi.stubGlobal("fetch", fetchMock);
    const bridge = createMockBridge({
      getAccessToken: async () => ({
        accessToken: "access",
        expiresAt: null,
      }),
      activateWithTerms,
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

    await waitFor(() => expect(activateWithTerms).toHaveBeenCalledTimes(1));
    expect(await screen.findByText("권한 화면")).toBeVisible();
    expect(activateWithTerms).toHaveBeenCalledWith({
      consents: [],
    });
  });
});
