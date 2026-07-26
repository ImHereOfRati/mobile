import "@/locales/i18n";
import "pretendard/dist/web/variable/pretendardvariable-dynamic-subset.css";
import "@/design-system/tokens.css";
import "@/design-system/typography.css";
import "@/design-system/primitives.css";
import "@/styles/global.css";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { App } from "@/app/App";

const rootElement = document.getElementById("root");

if (rootElement === null) {
  throw new Error("Root element was not found");
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
