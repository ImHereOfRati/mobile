import tokensSource from "./tokens.css?raw";

function readTheme(selector: RegExp) {
  const block = tokensSource.match(selector)?.[1];
  if (block === undefined) {
    throw new Error(`Theme block not found: ${selector.source}`);
  }

  return new Map(
    [...block.matchAll(/(--color-[\w-]+):\s*([^;]+);/g)].map((match) => [
      match[1],
      match[2].trim().toLowerCase(),
    ]),
  );
}

function luminance(hex: string) {
  const channels = [1, 3, 5]
    .map((index) => Number.parseInt(hex.slice(index, index + 2), 16) / 255)
    .map((channel) =>
      channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4,
    );

  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

function contrast(first: string, second: string) {
  const lighter = Math.max(luminance(first), luminance(second));
  const darker = Math.min(luminance(first), luminance(second));
  return (lighter + 0.05) / (darker + 0.05);
}

const light = readTheme(
  /:root,\s*:root\[data-theme="light"\]\s*\{([\s\S]*?)\}/,
);
const dark = readTheme(/:root\[data-theme="dark"\]\s*\{([\s\S]*?)\}/);

describe("design tokens", () => {
  it("keeps the adopted Flutter brand colors in the light theme", () => {
    expect(light.get("--color-primary")).toBe("#0071e3");
    expect(light.get("--color-text")).toBe("#191f28");
    expect(light.get("--color-text-secondary")).toBe("#6b7684");
    expect(light.get("--color-background")).toBe("#ffffff");
    expect(light.get("--color-surface")).toBe("#ffffff");
    expect(light.get("--color-divider")).toBe("#e9e9e7");
    expect(light.get("--color-error")).toBe("#ff3b30");
    expect(light.get("--color-success")).toBe("#34c759");
  });

  it("defines every semantic color in both themes", () => {
    expect([...dark.keys()].sort()).toEqual([...light.keys()].sort());
  });

  it.each([
    ["light text", light, "--color-text", "--color-background"],
    [
      "light secondary text",
      light,
      "--color-text-secondary",
      "--color-surface",
    ],
    ["light primary action", light, "--color-on-primary", "--color-primary"],
    ["light error action", light, "--color-on-error", "--color-error"],
    ["dark text", dark, "--color-text", "--color-background"],
    ["dark secondary text", dark, "--color-text-secondary", "--color-surface"],
    ["dark primary action", dark, "--color-on-primary", "--color-primary"],
    ["dark error action", dark, "--color-on-error", "--color-error"],
  ])("%s meets WCAG AA contrast", (_, theme, foreground, background) => {
    expect(
      contrast(theme.get(foreground)!, theme.get(background)!),
    ).toBeGreaterThanOrEqual(4.5);
  });
});
