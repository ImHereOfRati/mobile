import { createWindowBridge, type NativeBridge } from "@imhere/bridge-contract";
import { type PropsWithChildren, useEffect, useState } from "react";

import { AnalyticsProvider } from "@/analytics/AnalyticsProvider";

import { createBrowserPreviewBridge } from "./browser-preview-bridge";
import { BridgeContext } from "./bridge-context";

export function BridgeProvider({
  bridge: providedBridge,
  children,
}: PropsWithChildren<{ bridge?: NativeBridge }>) {
  const [connection, setConnection] = useState(() => {
    if (providedBridge !== undefined)
      return { bridge: providedBridge, destroy: () => {} };
    // Flutter injects JavaScript channels while the WebView document is being
    // attached. Do not permanently select the browser preview bridge during
    // that short window, or native-only calls such as getDeviceContacts are
    // lost for the first screen load.
    const isAndroidWebView = /; wv\)/i.test(navigator.userAgent);
    return window.ImHereShell === undefined && !isAndroidWebView
      ? { bridge: createBrowserPreviewBridge().bridge, destroy: () => {} }
      : null;
  });

  useEffect(() => {
    if (connection !== null || providedBridge !== undefined) return;
    let cancelled = false;
    let timer: number | undefined;
    const attempt = () => {
      if (cancelled) return;
      if (window.ImHereBridge === undefined) {
        timer = window.setTimeout(attempt, 50);
        return;
      }
      const candidate = createWindowBridge();
      void candidate.bridge
        .getAuthState()
        .then(() => {
          if (cancelled) {
            candidate.destroy();
            return;
          }
          setConnection(candidate);
        })
        .catch(() => {
          candidate.destroy();
          timer = window.setTimeout(attempt, 100);
        });
    };
    attempt();
    return () => {
      cancelled = true;
      if (timer !== undefined) window.clearTimeout(timer);
    };
  }, [connection, providedBridge]);

  useEffect(() => () => connection?.destroy(), [connection]);
  if (connection === null) return null;
  return (
    <BridgeContext.Provider value={connection.bridge}>
      <AnalyticsProvider>{children}</AnalyticsProvider>
    </BridgeContext.Provider>
  );
}
