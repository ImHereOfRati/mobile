import { describe, expect, it } from "vitest";

import { formatDeliveryStatus, normalizePushPath } from "./record-model";

describe("formatDeliveryStatus", () => {
  it("presents bridge delivery states in Korean", () => {
    expect(formatDeliveryStatus("completed")).toBe("완료");
    expect(formatDeliveryStatus("pending")).toBe("대기 중");
    expect(formatDeliveryStatus("failed")).toBe("실패");
  });
});

describe("normalizePushPath", () => {
  it("removes the WebView basename from native push paths", () => {
    expect(normalizePushPath("/app/record/notifications/3")).toBe(
      "/record/notifications/3",
    );
  });

  it("rejects external and malformed navigation targets", () => {
    expect(normalizePushPath("https://attacker.example")).toBe("/record");
    expect(normalizePushPath("//attacker.example")).toBe("/record");
    expect(normalizePushPath("\\record")).toBe("/record");
  });
});
