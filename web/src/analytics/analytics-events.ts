export interface AnalyticsEventMap {
  delivery_failed: {
    event_type: "arrival" | "departure";
    retry_count: number;
  };
  delivery_succeeded: {
    event_type: "arrival" | "departure";
    retry_count: number;
  };
  friend_request_sent: {
    source: "search";
  };
  geofence_deleted: {
    event_type: "arrival" | "departure" | "both";
  };
  geofence_saved: {
    event_type: "arrival" | "departure" | "both";
    mode: "create" | "edit";
    repeat_type: "none" | "daily" | "weekday" | "weekend" | "custom";
  };
  geofence_toggled: {
    active: boolean;
  };
  geofence_triggered: {
    event_type: "arrival" | "departure";
  };
  login_completed: {
    provider: "google" | "kakao";
  };
  login_failed: {
    provider: "google" | "kakao";
  };
  login_started: {
    provider: "google" | "kakao";
  };
  onboarding_ready: {
    missing_count: number;
  };
  screen_view: {
    screen: string;
  };
  terms_accepted: {
    optional_count: number;
    required_count: number;
  };
}

export type AnalyticsEventName = keyof AnalyticsEventMap;

export type AnalyticsEventParameters<Name extends AnalyticsEventName> =
  AnalyticsEventMap[Name];

export type SafeAnalyticsParameters = Record<string, boolean | number | string>;
