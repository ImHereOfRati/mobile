import { Suspense } from "react";
import { useTranslation } from "react-i18next";
import { Outlet } from "react-router-dom";

import { AppErrorBoundary } from "@/app/AppErrorBoundary";

export function AppRoot() {
  const { t } = useTranslation();

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
