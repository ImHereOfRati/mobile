import { beforeEach, describe, expect, it, vi } from "vitest";

import { BrowserAnalyticsSinks } from "./browser-analytics";

describe("BrowserAnalyticsSinks", () => {
  beforeEach(() => {
    document.head.innerHTML = "";
    delete window.clarity;
    delete window.dataLayer;
    delete window.gtag;
    vi.unstubAllEnvs();
  });

  it("does not load GA4 or Clarity before consent", () => {
    vi.stubEnv("VITE_GA_MEASUREMENT_ID", "G-TEST");
    vi.stubEnv("VITE_CLARITY_PROJECT_ID", "clarity-test");

    new BrowserAnalyticsSinks().setConsent(false);

    expect(document.querySelectorAll("script")).toHaveLength(0);
  });

  it("loads both sinks only after consent with advertising denied", () => {
    vi.stubEnv("VITE_GA_MEASUREMENT_ID", "G-TEST");
    vi.stubEnv("VITE_CLARITY_PROJECT_ID", "clarity-test");
    const sinks = new BrowserAnalyticsSinks();

    sinks.setConsent(true);

    expect(
      document.querySelector<HTMLScriptElement>("#imhere-google-analytics")
        ?.src,
    ).toContain("googletagmanager.com/gtag/js?id=G-TEST");
    expect(
      document.querySelector<HTMLScriptElement>("#imhere-clarity")?.src,
    ).toContain("clarity.ms/tag/clarity-test");
    expect(window.dataLayer).toContainEqual([
      "consent",
      "update",
      {
        ad_personalization: "denied",
        ad_storage: "denied",
        ad_user_data: "denied",
        analytics_storage: "granted",
      },
    ]);
    expect(window.clarity?.q).toContainEqual([
      "consentv2",
      {
        ad_Storage: "denied",
        analytics_Storage: "granted",
      },
    ]);
  });
});
