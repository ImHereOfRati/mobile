import { createMockBridge } from "@imhere/bridge-contract";
import { render, screen, waitFor } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import RecordPage from "./RecordPage";

const envelope = (data: unknown) =>
  JSON.stringify({ imhereResponseCode: "SUCCESS", message: "ok", data });

afterEach(() => vi.unstubAllGlobals());

describe("RecordPage", () => {
  it("combines native records with server requests and refreshes on resume", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(
        async () => new Response(envelope({ content: [], hasNext: false })),
      ),
    );
    const controller = createMockBridge({
      getAccessToken: async () => ({ accessToken: "token" }),
      queryNotifications: async () => ({
        items: [
          {
            id: 1,
            title: "도착 알림",
            body: "민수가 회사에 도착했어요.",
            createdAt: "2026-07-26T00:00:00Z",
          },
        ],
      }),
      queryRecords: async () => ({
        items: [
          {
            id: 2,
            geofenceId: 7,
            geofenceName: "회사",
            eventType: "arrival",
            status: "completed",
            occurredAt: "2026-07-26T00:00:00Z",
            message: "회사에 도착했습니다.",
          },
        ],
      }),
    });
    const { container } = render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter>
          <RecordPage screen="overview" />
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(
      await screen.findByRole("heading", { name: "도착 알림" }),
    ).toBeVisible();
    expect(screen.getByRole("heading", { name: "회사" })).toBeVisible();
    expect((await axe.run(container)).violations).toEqual([]);

    const before = controller.calls.filter(
      (call) => call.method === "queryNotifications",
    ).length;
    controller.emit("onAppResumed", undefined);
    await waitFor(() =>
      expect(
        controller.calls.filter((call) => call.method === "queryNotifications")
          .length,
      ).toBeGreaterThan(before),
    );
  });
});
