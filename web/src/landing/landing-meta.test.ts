import { describe, expect, it } from "vitest";

import landingHtml from "../../landing/index.html?raw";

describe("landing social metadata", () => {
  it("keeps crawler-visible metadata in static HTML", () => {
    expect(landingHtml).toContain('property="og:title"');
    expect(landingHtml).toContain('property="og:description"');
    expect(landingHtml).toContain('name="twitter:card" content="summary"');
    expect(landingHtml).toContain('href="https://imhere.ratiko.co.kr/"');
    expect(landingHtml).toContain("ImHere | 위치 기반 서비스");
  });
});
