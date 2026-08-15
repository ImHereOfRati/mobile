import { fireEvent, render, screen, within } from "@testing-library/react";
import axe from "axe-core";
import { vi } from "vitest";

import { LandingPage } from "./LandingPage";

vi.mock("@/landing/JourneyMap", () => ({
  JourneyMap: ({ onArrival }: { onArrival: () => void }) => (
    <button type="button" onClick={onArrival}>
      도착 시뮬레이션
    </button>
  ),
}));

describe("LandingPage", () => {
  it("shows only the accepted friend when selecting a notification target", () => {
    render(<LandingPage />);

    fireEvent.click(screen.getByRole("button", { name: "수락하기" }));

    const recipients = screen.getByRole("radiogroup", {
      name: "알림 대상",
    });
    const options = within(recipients).getAllByRole("radio");
    const save = screen.getByRole("button", {
      name: "장소와 알림 대상 설정",
    });

    expect(options).toHaveLength(1);
    expect(options[0]).toHaveAccessibleName(/철수/);
    expect(save).toBeDisabled();

    fireEvent.click(options[0]);
    expect(options[0]).toHaveAttribute("aria-checked", "true");
    expect(save).toBeEnabled();
  });

  it("opens the install popup as soon as arrival is reported", async () => {
    const { container } = render(<LandingPage />);

    fireEvent.click(screen.getByRole("button", { name: "도착 시뮬레이션" }));

    expect(screen.getByRole("dialog", { name: "ImHere 설치" })).toBeVisible();
    expect(screen.getByText("서울 시청 · 150m")).toBeVisible();
    expect((await axe.run(container)).violations).toEqual([]);
  });
});
