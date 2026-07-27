import { Suspense, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Outlet, useLocation } from "react-router-dom";

import { useAnalytics } from "@/analytics/analytics-context";
import { AppErrorBoundary } from "@/app/AppErrorBoundary";

export function AppRoot() {
  const { t } = useTranslation();
  const location = useLocation();
  const { ready, track } = useAnalytics();

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
