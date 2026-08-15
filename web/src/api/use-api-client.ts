import { useMemo } from "react";

import { ApiClient } from "@/api/api-client";
import { browserPreviewFetch } from "@/api/browser-preview-api";
import { useBridge } from "@/bridge/bridge-context";

export function useApiClient() {
  const bridge = useBridge();
  return useMemo(
    () =>
      new ApiClient(
        import.meta.env.VITE_API_BASE_URL || window.location.origin,
        {
          getAccessToken: () => bridge.getAccessToken(),
          refreshAccessToken: () => bridge.refreshAccessToken(),
        },
        import.meta.env.MODE === "development" &&
          window.ImHereBridge === undefined
          ? browserPreviewFetch
          : globalThis.fetch,
      ),
    [bridge],
  );
}
