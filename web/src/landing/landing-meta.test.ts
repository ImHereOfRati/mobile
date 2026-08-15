import { describe, expect, it } from "vitest";

import landingHtml from "../../landing/index.html?raw";

describe("landing social metadata", () => {
  it("keeps crawler-visible metadata in static HTML", () => {
    expect(landingHtml).toContain('property="og:title"');
    expect(landingHtml).toContain('property="og:description"');
    expect(landingHtml).toContain('property="og:url"');
    expect(landingHtml).toContain('property="og:image"');
    expect(landingHtml).toContain(
      'content="https://imhere.ratiko.co.kr/og-image.svg"',
    );
    expect(landingHtml).toContain(
      'name="twitter:card" content="summary_large_image"',
    );
    expect(landingHtml).toContain('name="twitter:image"');
    expect(landingHtml).toContain('href="/assets/app-logo.svg"');
    expect(landingHtml).toContain('rel="apple-touch-icon"');
    expect(landingHtml).toContain('type="application/ld+json"');
    expect(landingHtml).toContain('"@type": "SoftwareApplication"');
    expect(landingHtml).toContain('href="/sitemap.xml"');
    expect(landingHtml).toContain('href="https://imhere.ratiko.co.kr/"');
    expect(landingHtml).toContain("ImHere | 위치 기반 알림 서비스");
  });
});
