import { describe, expect, it, vi } from "vitest";

import {
  MapProxyService,
  reverseGeocodeAddress,
  reverseGeocodeLabel,
} from "./map-proxy-service";

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
    expect(reverseGeocodeLabel({}, 37.5665, 126.978)).toBe("37.5665, 126.9780");
  });
});

describe("MapProxyService", () => {
  it("extracts the reverse-geocoded place name and address", () => {
    const response = {
      results: [
        {
          name: "서울시청",
          region: {
            area0: { name: "kr" },
            area1: { name: "서울특별시" },
            area2: { name: "중구" },
          },
          land: { name: "세종대로", number1: "110" },
        },
      ],
    };

    expect(reverseGeocodeAddress(response, 37.5665, 126.978)).toBe(
      "서울특별시 중구 세종대로 110",
    );
  });

  it("keeps successful places when another place cannot be geocoded", async () => {
    const api = {
      request: vi.fn(async (path: string) => {
        if (path.includes("local-search")) {
          return {
            items: [
              {
                title: "<b>서울시청</b>",
                roadAddress: "서울 중구 세종대로 110",
              },
              { title: "실패 장소", roadAddress: "실패 주소" },
            ],
          };
        }
        if (path.includes(encodeURIComponent("실패 주소"))) {
          throw new Error("upstream failure");
        }
        return {
          addresses: [
            {
              roadAddress: "서울 중구 세종대로 110",
              x: "126.978",
              y: "37.5665",
            },
          ],
        };
      }),
    };

    await expect(
      new MapProxyService(api as never).searchPlaces("서울시청"),
    ).resolves.toEqual([
      {
        title: "서울시청",
        address: "서울 중구 세종대로 110",
        latitude: 37.5665,
        longitude: 126.978,
      },
    ]);
  });
});
