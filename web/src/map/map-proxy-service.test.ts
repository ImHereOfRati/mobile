import { describe, expect, it } from "vitest";

import { reverseGeocodeLabel } from "./map-proxy-service";

describe("reverseGeocodeLabel", () => {
  it("builds the compact region label used by migrated records", () => {
    expect(
      reverseGeocodeLabel(
        {
          results: [
            {
              region: {
                area1: { name: "서울특별시" },
                area2: { name: "중구" },
              },
            },
          ],
        },
        37.5665,
        126.978,
      ),
    ).toBe("서울특별시 중구");
  });

  it("falls back to coordinates when the proxy has no region", () => {
    expect(reverseGeocodeLabel({}, 37.5665, 126.978)).toBe(
      "37.5665, 126.9780",
    );
  });
});
