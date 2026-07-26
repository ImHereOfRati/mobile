import "pretendard/dist/web/variable/pretendardvariable-dynamic-subset.css";
import "@/design-system/tokens.css";
import "@/landing/landing.css";

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { LandingPage } from "@/landing/LandingPage";

const rootElement = document.getElementById("landing-root");

if (rootElement === null) {
  throw new Error("Landing root element was not found");
}

createRoot(rootElement).render(
  <StrictMode>
    <LandingPage />
  </StrictMode>,
);
