export interface AnalyticsEventMap {
  friend_request_sent: {
    source: "search";
  };
  geofence_deleted: {
    event_type: "arrival" | "departure" | "both";
  };
  geofence_saved: {
    event_type: "arrival" | "departure" | "both";
    mode: "create" | "edit";
  };
  geofence_toggled: {
    active: boolean;
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
  permission_requested: {
    permission: string;
    status: string;
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
