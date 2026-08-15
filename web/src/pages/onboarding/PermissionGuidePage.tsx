import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { Button } from "@/design-system";

export default function PermissionGuidePage({
  kind,
}: {
  kind: "location" | "battery";
}) {
  const bridge = useBridge();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const location = kind === "location";
  const [opening, setOpening] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function openSettings() {
    setOpening(true);
    setError(null);
    try {
      await bridge.requestPermission({
        permission: location ? "locationAlways" : "batteryOptimization",
      });
    } catch {
      setError(t("onboarding.permissionGuide.openFailed"));
    } finally {
      setOpening(false);
    }
  }

  return (
    <main className="onboarding">
      <section
        className="onboarding__panel onboarding__panel--centered"
        aria-labelledby="guide-title"
      >
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">
            {t("onboarding.permissionGuide.eyebrow")}
          </p>
          <h1 id="guide-title">
            {location
              ? t("onboarding.permissionGuide.location.title")
              : t("onboarding.permissionGuide.battery.title")}
          </h1>
          <p className="onboarding__description">
            {location
              ? t("onboarding.permissionGuide.location.description")
              : t("onboarding.permissionGuide.battery.description")}
          </p>
        </header>
        <ol className="onboarding__list">
          <li>{t("onboarding.permissionGuide.openStep")}</li>
          <li>
            {location
              ? t("onboarding.permissionGuide.location.step")
              : t("onboarding.permissionGuide.battery.step")}
          </li>
          <li>{t("onboarding.permissionGuide.returnStep")}</li>
        </ol>
        <Button loading={opening} onClick={() => void openSettings()}>
          {t("onboarding.permissionGuide.openSettings")}
        </Button>
        <Button variant="secondary" onClick={() => navigate(-1)}>
          {t("onboarding.permissionGuide.back")}
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
