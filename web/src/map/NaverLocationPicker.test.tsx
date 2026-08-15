import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { NaverLocationPicker } from "./NaverLocationPicker";

const value = {
  latitude: 37.5665,
  longitude: 126.978,
  radiusMeters: 250 as const,
};

const reverseGeocode = async () => ({
  results: [
    {
      name: "서울시청",
      region: {
        area1: { name: "서울특별시" },
        area2: { name: "중구" },
      },
      land: { name: "세종대로", number1: "110" },
    },
  ],
});

describe("NaverLocationPicker", () => {
  it("shows the intentional browser preview fallback without loading the SDK", async () => {
    const loadSdk = vi.fn(async () => undefined);
    render(
      <NaverLocationPicker
        clientId="browser"
        value={value}
        onChange={vi.fn()}
        reverseGeocode={reverseGeocode}
        searchPlaces={async () => []}
        loadSdk={loadSdk}
      />,
    );

    expect(
      await screen.findByText("지도를 불러오지 못했어요"),
    ).toBeInTheDocument();
    expect(loadSdk).not.toHaveBeenCalled();
  });

  it("changes between the three supported radii", () => {
    const onChange = vi.fn();
    render(
      <NaverLocationPicker
        clientId="public-client"
        value={value}
        onChange={onChange}
        reverseGeocode={reverseGeocode}
        searchPlaces={async () => []}
        loadSdk={async () => undefined}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "1km" }));
    expect(onChange).toHaveBeenCalledWith({
      ...value,
      radiusMeters: 1000,
    });
  });

  it("keeps proxy address search available when the SDK fails", async () => {
    const onChange = vi.fn();
    const searchPlaces = vi.fn(async () => [
      {
        title: "서울시청",
        address: "서울특별시 중구 세종대로 110",
        latitude: 37.5663,
        longitude: 126.9779,
      },
    ]);
    render(
      <NaverLocationPicker
        clientId="public-client"
        value={value}
        onChange={onChange}
        reverseGeocode={reverseGeocode}
        searchPlaces={searchPlaces}
        loadSdk={async () => {
          throw new Error("quota");
        }}
      />,
    );

    expect(
      await screen.findByText("지도를 불러오지 못했어요"),
    ).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText("장소 검색"), {
      target: { value: "서울시청" },
    });
    fireEvent.click(screen.getByRole("button", { name: "검색" }));
    await waitFor(() => expect(searchPlaces).toHaveBeenCalledWith("서울시청"));
    fireEvent.click(await screen.findByRole("button", { name: /서울시청/ }));
    expect(onChange).toHaveBeenLastCalledWith({
      ...value,
      address: "서울특별시 중구 세종대로 110",
      latitude: 37.5663,
      longitude: 126.9779,
      name: "서울시청",
    });
  });

  it("proposes the reverse geocoded place name alongside the address", async () => {
    const onChange = vi.fn();
    render(
      <NaverLocationPicker
        clientId="browser"
        value={{ ...value, address: "" }}
        onChange={onChange}
        reverseGeocode={reverseGeocode}
        searchPlaces={async () => []}
      />,
    );

    await waitFor(() =>
      expect(onChange).toHaveBeenCalledWith({
        ...value,
        address: "서울특별시 중구 세종대로 110",
        name: "서울시청",
      }),
    );
  });

  it("keeps the current selection when reverse geocoding fails", async () => {
    const onChange = vi.fn();
    const reverseGeocodeFailure = vi.fn(async () => {
      throw new Error("upstream failure");
    });
    render(
      <NaverLocationPicker
        clientId="browser"
        value={{ ...value, name: "이전 장소" }}
        onChange={onChange}
        reverseGeocode={reverseGeocodeFailure}
        searchPlaces={async () => []}
      />,
    );

    await waitFor(() => expect(reverseGeocodeFailure).toHaveBeenCalled());
    expect(onChange).not.toHaveBeenCalled();
  });

  it("skips the initial reverse geocoding while editing an existing place", async () => {
    const reverseGeocodeSpy = vi.fn(reverseGeocode);
    render(
      <NaverLocationPicker
        clientId="browser"
        value={{ ...value, name: "회사", address: "서울시 중구 세종대로" }}
        onChange={vi.fn()}
        resolveInitialLocation={false}
        reverseGeocode={reverseGeocodeSpy}
        searchPlaces={async () => []}
      />,
    );

    expect(
      await screen.findByText("지도를 불러오지 못했어요"),
    ).toBeInTheDocument();
    expect(reverseGeocodeSpy).not.toHaveBeenCalled();
  });
});
