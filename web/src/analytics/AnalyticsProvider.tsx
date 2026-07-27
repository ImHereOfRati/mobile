import {
  type PropsWithChildren,
  useCallback,
  useEffect,
  useMemo,
  useState,
} from "react";

import { useBridge } from "@/bridge/bridge-context";

import { AnalyticsClient } from "./analytics-client";
import { AnalyticsContext } from "./analytics-context";
import type {
  AnalyticsEventName,
  AnalyticsEventParameters,
} from "./analytics-events";

export function AnalyticsProvider({ children }: PropsWithChildren) {
  const bridge = useBridge();
  const client = useMemo(() => new AnalyticsClient(bridge), [bridge]);
  const [ready, setReady] = useState(false);
  const [consentGranted, setConsentGranted] = useState(false);

  useEffect(() => {
    let active = true;
    void client.synchronizeConsent().then((granted) => {
      if (!active) return;
      setConsentGranted(granted);
      setReady(true);
    });
    return () => {
      active = false;
    };
  }, [client]);

  const setConsent = useCallback(
    async (granted: boolean) => {
      await client.setConsent(granted);
      setConsentGranted(granted);
    },
    [client],
  );
  const track = useCallback(
    <Name extends AnalyticsEventName>(
      name: Name,
      parameters: AnalyticsEventParameters<Name>,
    ) => client.track(name, parameters),
    [client],
  );
  const value = useMemo(
    () => ({ consentGranted, ready, setConsent, track }),
    [consentGranted, ready, setConsent, track],
  );

  return (
    <AnalyticsContext.Provider value={value}>
      {children}
    </AnalyticsContext.Provider>
  );
}
