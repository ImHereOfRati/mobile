import { render, screen } from "@testing-library/react";

import { AppErrorBoundary } from "@/app/AppErrorBoundary";

function BrokenScreen(): never {
  throw new Error("render failure");
}

describe("AppErrorBoundary", () => {
  it("renders a Korean fallback after an unexpected render error", () => {
    const consoleError = vi
      .spyOn(console, "error")
      .mockImplementation(() => undefined);

    render(
      <AppErrorBoundary>
        <BrokenScreen />
      </AppErrorBoundary>,
    );

    expect(
      screen.getByRole("heading", {
        name: "화면을 표시할 수 없습니다.",
      }),
    ).toBeInTheDocument();

    consoleError.mockRestore();
  });
});
