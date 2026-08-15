import axe from "axe-core";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import { ThemeProvider } from "@/design-system";
import ComponentCatalogPage from "./ComponentCatalogPage";

function renderCatalog() {
  return render(
    <ThemeProvider>
      <ComponentCatalogPage />
    </ThemeProvider>,
  );
}

describe("component catalog", () => {
  it("shows the minimal pattern library and all five preview choices", async () => {
    const user = userEvent.setup();
    renderCatalog();

    expect(
      screen.getByRole("heading", { name: "ImHere 미니멀 UI 미리보기" }),
    ).toHaveClass("visually-hidden");
    expect(screen.getByRole("heading", { name: "기본 요소" })).toBeVisible();
    expect(
      screen.getByRole("heading", { name: "화면 미리보기" }),
    ).toBeVisible();
    expect(screen.queryByText(/일관되고 따뜻한/)).not.toBeInTheDocument();
    expect(screen.queryByText(/FOUNDATION/)).not.toBeInTheDocument();

    for (const label of ["장소", "장소 등록", "친구", "기록", "설정"]) {
      expect(screen.getByRole("button", { name: label })).toBeVisible();
    }
    expect(screen.getAllByText("서울 성동구 왕십리로 83")).not.toHaveLength(0);
    expect(screen.getByText("500m 내 진입 시")).toBeVisible();
    expect(screen.getByText("매일")).toBeVisible();

    await user.click(screen.getByRole("button", { name: "다크" }));
    expect(document.documentElement).toHaveAttribute("data-theme", "dark");
  });

  it("switches previews and exposes an interactive form error", async () => {
    const user = userEvent.setup();
    renderCatalog();

    await user.click(screen.getByRole("button", { name: "장소 등록" }));
    const name = screen.getByRole("textbox", { name: "장소 이름" });
    await user.clear(name);
    await user.click(screen.getByRole("button", { name: "장소 저장하기" }));
    expect(screen.getByRole("alert")).toHaveTextContent(
      "장소 이름을 입력해 주세요.",
    );

    await user.click(screen.getByRole("button", { name: "기록" }));
    await user.click(screen.getByRole("button", { name: "도착" }));
    expect(screen.getByText("우리 집에 도착했어요")).toBeVisible();
    expect(screen.queryByText("회사에서 출발했어요")).not.toBeInTheDocument();
  });

  it("opens the action sheet, traps focus, and restores focus on close", async () => {
    const user = userEvent.setup();
    renderCatalog();

    const trigger = screen.getByRole("button", { name: "우리 집 더보기" });
    await user.click(trigger);
    expect(screen.getByRole("dialog", { name: "우리 집 관리" })).toBeVisible();
    await waitFor(() =>
      expect(screen.getByRole("button", { name: "닫기" })).toHaveFocus(),
    );

    await user.keyboard("{Escape}");
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();
  });

  it("has no automatically detectable accessibility violations", async () => {
    const { container } = renderCatalog();
    const result = await axe.run(container, {
      rules: {
        "color-contrast": { enabled: false },
      },
    });

    expect(result.violations).toEqual([]);
  });
});
