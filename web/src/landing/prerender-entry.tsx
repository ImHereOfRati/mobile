import { renderToStaticMarkup } from "react-dom/server";

import { LandingPage } from "@/landing/LandingPage";

export function renderLandingMarkup(): string {
  return renderToStaticMarkup(<LandingPage />);
}
