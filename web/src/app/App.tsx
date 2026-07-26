import { QueryClientProvider } from "@tanstack/react-query";
import { RouterProvider } from "react-router-dom";

import { queryClient } from "@/api/query-client";
import { createAppRouter } from "@/app/router";
import { BridgeProvider } from "@/bridge/BridgeProvider";
import { ThemeProvider } from "@/design-system";

const router = createAppRouter();

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BridgeProvider>
        <ThemeProvider>
          <RouterProvider router={router} />
        </ThemeProvider>
      </BridgeProvider>
    </QueryClientProvider>
  );
}
