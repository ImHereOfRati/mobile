import type { NativeBridge } from "@imhere/bridge-contract";
import { useCallback, useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate } from "react-router-dom";

import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import { Button, LoadingState } from "@/design-system";

type Readiness = Awaited<ReturnType<NativeBridge["getAutoSendReadiness"]>>;

export default function PermissionPage() {
  const bridge = useBridge();
  const { track } = useAnalytics();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const permissionCopy = {
    locationAlways: [
      t("onboarding.permission.items.location.title"),
      t("onboarding.permission.items.location.description"),
    ],
    notification: [
      t("onboarding.permission.items.notification.title"),
      t("onboarding.permission.items.notification.description"),
    ],
    batteryOptimization: [
      t("onboarding.permission.items.battery.title"),
      t("onboarding.permission.items.battery.description"),
    ],
  } as const;
  const [readiness, setReadiness] = useState<Readiness | null>(null);
  const [requesting, setRequesting] = useState<
    keyof typeof permissionCopy | null
  >(null);
  const [error, setError] = useState<string | null>(null);
  const readyTracked = useRef(false);

  const refresh = useCallback(async () => {
    try {
      const value = await bridge.getAutoSendReadiness();
      setReadiness(value);
      setError(null);
      if (value.ready) {
        if (!readyTracked.current) {
          readyTracked.current = true;
          await track("onboarding_ready", {
            missing_count: value.missing.length,
          });
        }
        navigate("/geofence", { replace: true });
      }
    } catch {
      setError(t("onboarding.permission.checkFailed"));
    }
  }, [bridge, navigate, t, track]);

  useEffect(() => {
    const initialRefresh = setTimeout(() => void refresh(), 0);
    const unsubscribeResume = bridge.events.subscribe("onAppResumed", () => {
      void refresh();
    });
    const unsubscribePermission = bridge.events.subscribe(
      "onPermissionChanged",
      () => void refresh(),
    );
    return () => {
      clearTimeout(initialRefresh);
      unsubscribeResume();
      unsubscribePermission();
    };
  }, [bridge, refresh]);

  async function request(permission: keyof typeof permissionCopy) {
    setRequesting(permission);
    setError(null);
    try {
      await bridge.requestPermission({ permission });
      await refresh();
    } catch {
      setError(t("onboarding.permission.requestFailed"));
    } finally {
      setRequesting(null);
    }
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="permission-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">
            {t("onboarding.permission.eyebrow")}
          </p>
          <h1 id="permission-title">{t("onboarding.permission.title")}</h1>
          <p className="onboarding__description">
            {t("onboarding.permission.description")}
          </p>
        </header>
        {readiness === null && error === null ? (
          <LoadingState label={t("onboarding.permission.loading")} />
        ) : (
          <div className="onboarding__list">
            {Object.entries(permissionCopy).map(
              ([permission, [title, description]]) => {
                const complete =
                  permission === "locationAlways"
                    ? readiness?.locationAlways
                    : permission === "notification"
                      ? readiness?.notification
                      : readiness?.batteryOptimization;
                return (
                  <article key={permission} className="onboarding__permission">
                    <span aria-hidden="true">{complete ? "✓" : "○"}</span>
                    <div>
                      <strong>{title}</strong>
                      <p className="onboarding__meta">{description}</p>
                    </div>
                    <Button
                      variant={complete ? "ghost" : "secondary"}
                      disabled={complete || requesting !== null}
                      loading={requesting === permission}
                      onClick={() =>
                        void request(permission as keyof typeof permissionCopy)
                      }
                    >
                      {complete
                        ? t("onboarding.permission.complete")
                        : t("onboarding.permission.settings")}
                    </Button>
                  </article>
                );
              },
            )}
          </div>
        )}
        <div className="onboarding__permission-actions">
          <Link to="/location-permission-guide">
            {t("onboarding.permission.locationGuide")}
          </Link>
          <Link to="/battery-optimization-guide">
            {t("onboarding.permission.batteryGuide")}
          </Link>
        </div>
        <Button onClick={() => void refresh()}>
          {t("onboarding.permission.refresh")}
        </Button>
        {error === null ? null : (
          <p className="onboarding__error" role="alert">
            {error}
          </p>
        )}
      </section>
    </main>
  );
}
