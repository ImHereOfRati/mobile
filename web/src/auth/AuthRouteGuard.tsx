import { useEffect, useMemo, useState } from "react";
import { Navigate, Outlet, useLocation } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { type AuthSnapshot, resolveAuthRedirect } from "./auth-redirect-policy";

export interface AuthRouteGuardProps {
  auth: AuthSnapshot;
  autoSendReady: boolean;
  loading?: boolean;
}

export function AuthRouteGuard({
  auth,
  autoSendReady,
  loading = false,
}: AuthRouteGuardProps) {
  const location = useLocation();
  if (loading) {
    return (
      <main className="fallback-page" aria-busy="true">
        <p>인증 상태를 확인하고 있어요.</p>
      </main>
    );
  }

  const redirect = resolveAuthRedirect({
    auth,
    autoSendReady,
    requestedUrl: `${location.pathname}${location.search}${location.hash}`,
  });

  return redirect === null ? <Outlet /> : <Navigate replace to={redirect} />;
}

interface NativeGuardSnapshot {
  auth: AuthSnapshot;
  autoSendReady: boolean;
  requestedUrl: string;
}

export function NativeAuthRouteGuard() {
  const bridge = useBridge();
  const location = useLocation();
  const requestedUrl = useMemo(
    () => `${location.pathname}${location.search}${location.hash}`,
    [location.hash, location.pathname, location.search],
  );
  const [snapshot, setSnapshot] = useState<NativeGuardSnapshot | null>(null);

  useEffect(() => {
    let active = true;

    const refresh = async () => {
      setSnapshot(null);
      try {
        const [auth, readiness] = await Promise.all([
          bridge.getAuthState(),
          bridge.getAutoSendReadiness(),
        ]);
        if (active) {
          setSnapshot({
            auth,
            autoSendReady: readiness.ready,
            requestedUrl,
          });
        }
      } catch {
        if (active) {
          setSnapshot({
            auth: { authenticated: false, userStatus: null },
            autoSendReady: false,
            requestedUrl,
          });
        }
      }
    };

    void refresh();
    const unsubscribeResume = bridge.events.subscribe(
      "onAppResumed",
      () => void refresh(),
    );
    const unsubscribePermission = bridge.events.subscribe(
      "onPermissionChanged",
      () => void refresh(),
    );
    return () => {
      active = false;
      unsubscribeResume();
      unsubscribePermission();
    };
  }, [bridge, requestedUrl]);

  const current =
    snapshot?.requestedUrl === requestedUrl ? snapshot : null;
  return (
    <AuthRouteGuard
      auth={
        current?.auth ?? {
          authenticated: false,
          userStatus: null,
        }
      }
      autoSendReady={current?.autoSendReady ?? false}
      loading={current === null}
    />
  );
}
