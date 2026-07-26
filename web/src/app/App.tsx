import { RouterProvider } from "react-router-dom";

import { createAppRouter } from "@/app/router";
import { ThemeProvider } from "@/design-system";

const router = createAppRouter();

export function App() {
  return (
    <ThemeProvider>
      <RouterProvider router={router} />
    </ThemeProvider>
  );
}
