import { createContext, useContext } from "react";

import type {
  AnalyticsEventName,
  AnalyticsEventParameters,
} from "./analytics-events";

export interface AnalyticsContextValue {
  consentGranted: boolean;
  ready: boolean;
  setConsent(granted: boolean): Promise<void>;
  track<Name extends AnalyticsEventName>(
    name: Name,
    parameters: AnalyticsEventParameters<Name>,
  ): Promise<void>;
}

export const AnalyticsContext = createContext<AnalyticsContextValue | null>(
  null,
);

export function useAnalytics() {
  const value = useContext(AnalyticsContext);
  if (value === null) throw new Error("AnalyticsProvider is missing");
  return value;
}
