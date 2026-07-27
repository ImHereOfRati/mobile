import { describe, expect, it, vi } from "vitest";

import { getNativePageTitle, notifyNativeShell } from "./native-shell";

describe("native shell metadata", () => {
  it.each([
    ["/geofence", "장소"],
    ["/geofence/message", "장소 추가"],
    ["/friend/requests", "친구 요청"],
    ["/record/notifications/7", "받은 알림 상세"],
    ["/setting", "설정"],
  ])("maps %s to %s", (path, title) => {
    expect(getNativePageTitle(path)).toBe(title);
  });

  it("reports route changes through the dedicated shell channel", () => {
    const postMessage = vi.fn();
    window.ImHereShell = { postMessage };

    notifyNativeShell("/friend");

    expect(postMessage).toHaveBeenCalledWith(
      JSON.stringify({ path: "/friend", title: "친구" }),
    );
    delete window.ImHereShell;
  });
});
