import { describe, expect, it } from "vitest";

import landingPageSource from "@/landing/LandingPage.tsx?raw";
import landingMainSource from "@/landing/main.tsx?raw";

describe("landing copy and presentation", () => {
  it("introduces ImHere before inviting the visitor into the experience", () => {
    const productIndex = landingPageSource.indexOf('id="product-title"');
    const experienceIndex =
      landingPageSource.indexOf("철수에게 귀가 알림을 보내보세요");

    expect(productIndex).toBeGreaterThanOrEqual(0);
    expect(experienceIndex).toBeGreaterThan(productIndex);
  });

  it("does not present the experience as an interactive browser demo", () => {
    expect(landingPageSource).not.toContain("인터랙티브 데모");
    expect(landingPageSource).not.toContain("브라우저 체험");
    expect(landingPageSource).not.toContain("임꺽정");
    expect(landingPageSource).not.toContain("BrandMark");
  });

  it("uses Pretendard without the app title-font stylesheet", () => {
    expect(landingMainSource).toContain("pretendard");
    expect(landingMainSource).not.toContain("typography.css");
  });

  it("opens the install dialog after the experience", () => {
    expect(landingPageSource).toContain("설치하기");
    expect(landingPageSource).toContain("<InstallDialog");
  });
});
