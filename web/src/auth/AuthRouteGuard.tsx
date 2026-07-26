import { Navigate, Outlet, useLocation } from "react-router-dom";

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
