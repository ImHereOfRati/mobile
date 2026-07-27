const storageKey = "imhere.analytics-consent.v1";

export function loadAnalyticsConsent(storage: Storage = localStorage) {
  try {
    const value = storage.getItem(storageKey);
    return value === null ? null : value === "granted";
  } catch {
    return null;
  }
}

export function saveAnalyticsConsent(
  granted: boolean,
  storage: Storage = localStorage,
) {
  try {
    storage.setItem(storageKey, granted ? "granted" : "denied");
  } catch {
    // WebView privacy modes can make localStorage unavailable.
  }
}
