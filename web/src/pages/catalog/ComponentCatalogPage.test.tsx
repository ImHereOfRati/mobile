import axe from "axe-core";
import { render, screen } from "@testing-library/react";
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
  it("renders all primitive groups and switches themes", async () => {
    const user = userEvent.setup();
    renderCatalog();

    expect(
      screen.getByRole("heading", { name: /일관되고 따뜻한/ }),
    ).toBeVisible();
    expect(screen.getByRole("heading", { name: "버튼" })).toBeVisible();
    expect(screen.getByRole("heading", { name: "입력과 카드" })).toBeVisible();
    expect(
      screen.getByRole("heading", { name: "리스트와 피드백" }),
    ).toBeVisible();
    expect(
      screen.getByRole("heading", { name: "빈 상태와 로딩" }),
    ).toBeVisible();

    await user.click(screen.getByRole("button", { name: "다크" }));
    expect(document.documentElement).toHaveAttribute("data-theme", "dark");
  });

  it("opens and closes the accessible bottom sheet", async () => {
    const user = userEvent.setup();
    renderCatalog();

    await user.click(screen.getByRole("button", { name: "반경 선택 열기" }));
    expect(
      screen.getByRole("dialog", { name: "알림 반경을 선택하세요" }),
    ).toBeVisible();

    await user.keyboard("{Escape}");
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
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
