export type UserStatus = "pending" | "active" | "inactive" | null;

export interface AuthSnapshot {
  authenticated: boolean;
  userStatus: UserStatus;
}

const routes = {
  auth: "/auth",
  termsConsent: "/terms-consent",
  userPermission: "/user-permission",
  locationGuide: "/location-permission-guide",
  batteryGuide: "/battery-optimization-guide",
  geofence: "/geofence",
} as const;

const permissionGuideRoutes = new Set<string>([
  routes.userPermission,
  routes.locationGuide,
  routes.batteryGuide,
]);

export function resolveAuthRedirect({
  auth,
  autoSendReady,
  requestedUrl,
}: {
  auth: AuthSnapshot;
  autoSendReady: boolean;
  requestedUrl: string;
}): string | null {
  const requested = new URL(requestedUrl, "https://app.invalid");
  const matchedLocation = requested.pathname;
  const redirect = requested.pathname + requested.search + requested.hash;

  if (
    !auth.authenticated &&
    auth.userStatus !== "pending" &&
    auth.userStatus !== "inactive"
  ) {
    return matchedLocation === routes.auth
      ? null
      : withQuery(routes.auth, "redirect", redirect);
  }

  if (auth.userStatus === "pending") {
    return matchedLocation === routes.termsConsent ||
      matchedLocation.startsWith("/terms-detail/")
      ? null
      : withQuery(routes.termsConsent, "redirect", redirect);
  }

  if (auth.userStatus === "inactive") {
    return matchedLocation === routes.auth
      ? null
      : withQuery(routes.auth, "reason", "inactive");
  }

  if (!autoSendReady) {
    return permissionGuideRoutes.has(matchedLocation)
      ? null
      : withQuery(routes.userPermission, "redirect", redirect);
  }

  if (matchedLocation === routes.userPermission) {
    return (
      safeRedirect(requested.searchParams.get("redirect")) ?? routes.geofence
    );
  }

  if (
    matchedLocation === routes.locationGuide ||
    matchedLocation === routes.batteryGuide
  ) {
    return null;
  }

  if (
    matchedLocation === routes.auth ||
    matchedLocation === routes.termsConsent
  ) {
    return (
      safeRedirect(requested.searchParams.get("redirect")) ?? routes.geofence
    );
  }

  return null;
}

function withQuery(path: string, key: string, value: string) {
  const query = new URLSearchParams({ [key]: value });
  return `${path}?${query}`;
}

function safeRedirect(value: string | null) {
  return value?.startsWith("/") === true && !value.startsWith("//")
    ? value
    : null;
}
