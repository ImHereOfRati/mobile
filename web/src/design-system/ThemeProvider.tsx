import {
  type PropsWithChildren,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { BridgeContext } from "@/bridge/bridge-context";

import {
  type AppTheme,
  ThemeContext,
  type ThemeContextValue,
} from "./theme-context";
const storageKey = "imhere-theme";

function getInitialTheme(): AppTheme {
  const storedTheme = globalThis.localStorage?.getItem(storageKey);
  if (storedTheme === "light" || storedTheme === "dark") {
    return storedTheme;
  }

  return globalThis.matchMedia?.("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

export function ThemeProvider({ children }: PropsWithChildren) {
  const [theme, setTheme] = useState<AppTheme>(getInitialTheme);
  const bridge = useContext(BridgeContext);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    document.documentElement.style.colorScheme = theme;
    globalThis.localStorage?.setItem(storageKey, theme);
    void bridge
      ?.setStatusBarStyle({ style: theme === "dark" ? "light" : "dark" })
      .catch(() => undefined);
  }, [bridge, theme]);

  useEffect(() => {
    if (bridge === null) return;
    void bridge
      .getAppInfo()
      .then((info) => {
        if (info.theme === "light" || info.theme === "dark") {
          setTheme(info.theme);
        }
      })
      .catch(() => undefined);
    return bridge.events.subscribe("onThemeChanged", ({ theme: next }) => {
      if (next === "light" || next === "dark") setTheme(next);
      else {
        setTheme(
          matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light",
        );
      }
    });
  }, [bridge]);

  const value = useMemo<ThemeContextValue>(
    () => ({
      theme,
      setTheme,
      toggleTheme: () =>
        setTheme((currentTheme) =>
          currentTheme === "light" ? "dark" : "light",
        ),
    }),
    [theme],
  );

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
}
