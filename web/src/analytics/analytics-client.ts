import type { NativeBridge } from "@imhere/bridge-contract";

import {
  loadAnalyticsConsent,
  saveAnalyticsConsent,
} from "./analytics-consent";
import type {
  AnalyticsEventName,
  AnalyticsEventParameters,
  SafeAnalyticsParameters,
} from "./analytics-events";
import {
  BrowserAnalyticsSinks,
  type BrowserAnalytics,
} from "./browser-analytics";

const sensitiveParameter =
  /address|body|coordinate|display.?name|email|friend|lat(itude)?|lng|longitude|message|name|phone/i;

export class AnalyticsClient {
  private consentGranted = false;

  constructor(
    private readonly bridge: NativeBridge,
    private readonly browser: BrowserAnalytics = new BrowserAnalyticsSinks(),
    private readonly storage: Storage = localStorage,
  ) {}

  get hasConsent() {
    return this.consentGranted;
  }

  async synchronizeConsent() {
    const stored = loadAnalyticsConsent(this.storage);
    if (stored !== null) {
      await this.setConsent(stored, false);
      return stored;
    }

    // Authentication or account activation is not consent. Until the user
    // explicitly agrees to the optional analytics/marketing term, collection
    // must remain disabled.
    await this.setConsent(false, false);
    return false;
  }

  async setConsent(granted: boolean, persist = true) {
    this.consentGranted = granted;
    if (persist) saveAnalyticsConsent(granted, this.storage);
    this.browser.setConsent(granted);
    await this.bridge.setAnalyticsConsent({ granted }).catch(() => undefined);
  }

  async track<Name extends AnalyticsEventName>(
    name: Name,
    parameters: AnalyticsEventParameters<Name>,
  ) {
    if (!this.consentGranted) return;
    const safeParameters = sanitizeAnalyticsParameters(parameters);
    await Promise.allSettled([
      Promise.resolve(this.browser.trackGoogle(name, safeParameters)),
      Promise.resolve(this.browser.trackClarity(name)),
      this.bridge.logEvent({ name, parameters: safeParameters }),
    ]);
  }
}

export function sanitizeAnalyticsParameters(
  parameters: Record<string, boolean | number | string>,
): SafeAnalyticsParameters {
  return Object.fromEntries(
    Object.entries(parameters).filter(([key]) => !sensitiveParameter.test(key)),
  );
}
