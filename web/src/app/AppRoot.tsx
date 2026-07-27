import { Suspense, useEffect, useLayoutEffect } from "react";
import { useTranslation } from "react-i18next";
import { Outlet, useLocation, useNavigate } from "react-router-dom";

import { useAnalytics } from "@/analytics/analytics-context";
import { AppErrorBoundary } from "@/app/AppErrorBoundary";
import { notifyNativeShell } from "@/app/native-shell";

export function AppRoot() {
  const { t } = useTranslation();
  const location = useLocation();
  const navigate = useNavigate();
  const { ready, track } = useAnalytics();
  const embeddedInNativeShell = window.ImHereShell !== undefined;

  useLayoutEffect(() => {
    if (!embeddedInNativeShell) return;
    document.documentElement.dataset.nativeShell = "true";
    return () => {
      delete document.documentElement.dataset.nativeShell;
    };
  }, [embeddedInNativeShell]);

  useEffect(() => {
    window.__imhereNavigate = (path) => navigate(path);
    return () => {
      delete window.__imhereNavigate;
    };
  }, [navigate]);

  useEffect(() => {
    notifyNativeShell(location.pathname);
  }, [location.pathname]);

  useEffect(() => {
    if (ready) {
      void track("screen_view", { screen: location.pathname });
    }
  }, [location.pathname, ready, track]);

  return (
    <AppErrorBoundary>
      <Suspense
        fallback={
          <main className="fallback-page" aria-busy="true">
            <p>{t("common.loading")}</p>
          </main>
        }
      >
        <Outlet />
      </Suspense>
    </AppErrorBoundary>
  );
}
