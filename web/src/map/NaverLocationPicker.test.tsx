import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { NaverLocationPicker } from "./NaverLocationPicker";

const value = {
  latitude: 37.5665,
  longitude: 126.978,
  radiusMeters: 250 as const,
};

describe("NaverLocationPicker", () => {
  it("changes between the three supported radii", () => {
    const onChange = vi.fn();
    render(
      <NaverLocationPicker
        clientId="public-client"
        value={value}
        onChange={onChange}
        searchPlaces={async () => []}
        loadSdk={async () => new Promise(() => {})}
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
    });
  });
});
