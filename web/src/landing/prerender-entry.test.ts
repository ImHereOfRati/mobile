import { describe, expect, it } from "vitest";

import { renderLandingMarkup } from "@/landing/prerender-entry";

describe("landing prerender markup", () => {
  it("renders crawler-visible content for the landing page", () => {
    const markup = renderLandingMarkup();

    expect(markup).toContain('id="product-title"');
    expect(markup).toContain("ImHere는 어떤 서비스인가요?");
    expect(markup).toContain("ImHere는 무료인가요?");
  });
});
