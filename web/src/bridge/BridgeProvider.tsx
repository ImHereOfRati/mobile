import { createWindowBridge, type NativeBridge } from "@imhere/bridge-contract";
import { type PropsWithChildren, useEffect, useState } from "react";

import { AnalyticsProvider } from "@/analytics/AnalyticsProvider";

import { createBrowserPreviewBridge } from "./browser-preview-bridge";
import { BridgeContext } from "./bridge-context";

export function BridgeProvider({
  bridge: providedBridge,
  children,
}: PropsWithChildren<{ bridge?: NativeBridge }>) {
  const [connection] = useState(() => {
    if (providedBridge !== undefined) {
      return { bridge: providedBridge, destroy: () => {} };
    }
    return window.ImHereBridge === undefined
      ? { bridge: createBrowserPreviewBridge().bridge, destroy: () => {} }
      : createWindowBridge();
  });

  useEffect(() => () => connection.destroy(), [connection]);
  return (
    <BridgeContext.Provider value={connection.bridge}>
      <AnalyticsProvider>{children}</AnalyticsProvider>
    </BridgeContext.Provider>
  );
}
