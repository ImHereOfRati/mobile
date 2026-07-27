import type {
  AnalyticsEventName,
  SafeAnalyticsParameters,
} from "./analytics-events";

type ConsentValue = "denied" | "granted";
type GtagArguments = [command: string, target: string, value?: unknown];
type ClarityFunction = {
  (...args: unknown[]): void;
  q?: unknown[][];
};

declare global {
  interface Window {
    clarity?: ClarityFunction;
    dataLayer?: unknown[][];
    gtag?: (...args: GtagArguments) => void;
  }
}

export interface BrowserAnalytics {
  setConsent(granted: boolean): void;
  trackClarity(name: AnalyticsEventName): void;
  trackGoogle(
    name: AnalyticsEventName,
    parameters: SafeAnalyticsParameters,
  ): void;
}

export class BrowserAnalyticsSinks implements BrowserAnalytics {
  private googleLoaded = false;
  private clarityLoaded = false;

  setConsent(granted: boolean) {
    if (granted) {
      this.loadGoogle();
      this.loadClarity();
    }

    const analyticsStorage: ConsentValue = granted ? "granted" : "denied";
    window.gtag?.("consent", "update", {
      ad_personalization: "denied",
      ad_storage: "denied",
      ad_user_data: "denied",
      analytics_storage: analyticsStorage,
    });
    window.clarity?.("consentv2", {
      ad_Storage: "denied",
      analytics_Storage: analyticsStorage,
    });
  }

  trackGoogle(name: AnalyticsEventName, parameters: SafeAnalyticsParameters) {
    window.gtag?.("event", name, parameters);
  }

  trackClarity(name: AnalyticsEventName) {
    window.clarity?.("event", name);
  }

  private loadGoogle() {
    const measurementId = import.meta.env.VITE_GA_MEASUREMENT_ID?.trim();
    if (this.googleLoaded || !measurementId) return;
    this.googleLoaded = true;

    window.dataLayer ??= [];
    window.gtag ??= (...args) => {
      window.dataLayer?.push(args);
    };
    window.gtag("consent", "default", {
      ad_personalization: "denied",
      ad_storage: "denied",
      ad_user_data: "denied",
      analytics_storage: "denied",
    });
    window.gtag("consent", "update", {
      ad_personalization: "denied",
      ad_storage: "denied",
      ad_user_data: "denied",
      analytics_storage: "granted",
    });
    window.gtag("js", new Date().toISOString());
    window.gtag("config", measurementId, { send_page_view: false });

    appendScript(
      "imhere-google-analytics",
      `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(measurementId)}`,
    );
  }

  private loadClarity() {
    const projectId = import.meta.env.VITE_CLARITY_PROJECT_ID?.trim();
    if (this.clarityLoaded || !projectId) return;
    this.clarityLoaded = true;

    window.clarity ??= Object.assign(
      (...args: unknown[]) => {
        window.clarity?.q?.push(args);
      },
      { q: [] as unknown[][] },
    );
    appendScript(
      "imhere-clarity",
      `https://www.clarity.ms/tag/${encodeURIComponent(projectId)}`,
    );
  }
}

function appendScript(id: string, source: string) {
  if (document.getElementById(id) !== null) return;
  const script = document.createElement("script");
  script.async = true;
  script.id = id;
  script.src = source;
  document.head.append(script);
}
