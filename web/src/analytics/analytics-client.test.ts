import { createMockBridge } from "@imhere/bridge-contract";
import { beforeEach, describe, expect, it } from "vitest";

import {
  AnalyticsClient,
  sanitizeAnalyticsParameters,
} from "./analytics-client";
import type {
  AnalyticsEventName,
  SafeAnalyticsParameters,
} from "./analytics-events";
import type { BrowserAnalytics } from "./browser-analytics";

class FakeBrowserAnalytics implements BrowserAnalytics {
  consent: boolean[] = [];
  clarity: AnalyticsEventName[] = [];
  google: Array<{
    name: AnalyticsEventName;
    parameters: SafeAnalyticsParameters;
  }> = [];

  setConsent(granted: boolean) {
    this.consent.push(granted);
  }

  trackClarity(name: AnalyticsEventName) {
    this.clarity.push(name);
  }

  trackGoogle(name: AnalyticsEventName, parameters: SafeAnalyticsParameters) {
    this.google.push({ name, parameters });
  }
}

describe("AnalyticsClient", () => {
  beforeEach(() => localStorage.clear());

  it("does not fan out events before analytics consent", async () => {
    const controller = createMockBridge({
      getAuthState: async () => ({
        authenticated: false,
        userStatus: null,
      }),
    });
    const browser = new FakeBrowserAnalytics();
    const client = new AnalyticsClient(
      controller.bridge,
      browser,
      localStorage,
    );

    await client.synchronizeConsent();
    await client.track("screen_view", { screen: "/auth" });

    expect(browser.consent).toEqual([false]);
    expect(browser.google).toHaveLength(0);
    expect(browser.clarity).toHaveLength(0);
    expect(
      controller.calls.filter((call) => call.method === "logEvent"),
    ).toHaveLength(0);
  });

  it("fans out one safe event to GA4, Clarity, and Firebase bridge", async () => {
    const controller = createMockBridge();
    const browser = new FakeBrowserAnalytics();
    const client = new AnalyticsClient(
      controller.bridge,
      browser,
      localStorage,
    );

    await client.setConsent(true);
    await client.track("geofence_saved", {
      event_type: "arrival",
      mode: "create",
      repeat_type: "weekday",
    });

    expect(browser.google).toEqual([
      {
        name: "geofence_saved",
        parameters: {
          event_type: "arrival",
          mode: "create",
          repeat_type: "weekday",
        },
      },
    ]);
    expect(browser.clarity).toEqual(["geofence_saved"]);
    expect(controller.calls).toContainEqual({
      method: "logEvent",
      args: [
        {
          name: "geofence_saved",
          parameters: {
            event_type: "arrival",
            mode: "create",
            repeat_type: "weekday",
          },
        },
      ],
    });
  });

  it("keeps analytics disabled for an activated member without explicit consent", async () => {
    const controller = createMockBridge({
      getAuthState: async () => ({
        authenticated: true,
        userStatus: "active",
      }),
    });
    const browser = new FakeBrowserAnalytics();
    const client = new AnalyticsClient(
      controller.bridge,
      browser,
      localStorage,
    );

    expect(await client.synchronizeConsent()).toBe(false);
    expect(localStorage.getItem("imhere.analytics-consent.v1")).toBeNull();
    expect(controller.calls).toContainEqual({
      method: "setAnalyticsConsent",
      args: [{ granted: false }],
    });
  });

  it("drops sensitive parameter names before dispatch", () => {
    expect(
      sanitizeAnalyticsParameters({
        address: "서울",
        event_type: "arrival",
        latitude: 37.5,
        message_body: "도착",
        retry_count: 1,
      }),
    ).toEqual({
      event_type: "arrival",
      retry_count: 1,
    });
  });
});
