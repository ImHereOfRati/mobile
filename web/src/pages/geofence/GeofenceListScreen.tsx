import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { BottomSheet, Button, EmptyState, LoadingState } from "@/design-system";

import type { Geofence } from "./geofence-model";
import { loadGeofences } from "./geofence-service";

export function GeofenceListScreen() {
  const { t } = useTranslation();
  const bridge = useBridge();
  const navigate = useNavigate();
  const [items, setItems] = useState<Geofence[] | null>(null);
  const [readiness, setReadiness] =
    useState<BridgeMethodResult<"getAutoSendReadiness"> | null>(null);
  const [locationEnabled, setLocationEnabled] = useState<boolean | null>(null);
  const [platform, setPlatform] =
    useState<BridgeMethodResult<"getAppInfo">["platform"]>("browser");
  const [error, setError] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Geofence | null>(null);

  const load = useCallback(async () => {
    const [geofences, autoSend, location, appInfo] = await Promise.allSettled([
      loadGeofences(bridge),
      bridge.getAutoSendReadiness(),
      bridge.getLocationServiceStatus(),
      bridge.getAppInfo(),
    ]);
    if (geofences.status === "fulfilled") {
      setItems(geofences.value);
      setError(null);
    } else {
      setItems([]);
      setError(t("geofence.list.loadError"));
    }
    if (autoSend.status === "fulfilled") setReadiness(autoSend.value);
    if (location.status === "fulfilled") {
      setLocationEnabled(location.value.status === "enabled");
    }
    if (appInfo.status === "fulfilled") setPlatform(appInfo.value.platform);
  }, [bridge, t]);

  useEffect(() => {
    const initialLoad = globalThis.setTimeout(() => void load(), 0);
    const unsubscribe = bridge.events.subscribe(
      "onAppResumed",
      () => void load(),
    );
    return () => {
      globalThis.clearTimeout(initialLoad);
      unsubscribe();
    };
  }, [bridge, load]);

  async function toggleActive(item: Geofence, active: boolean) {
    const updated = await bridge.setGeofenceActive({ id: item.id, active });
    setItems(
      (current) =>
        current?.map((value) => (value.id === updated.id ? updated : value)) ??
        [],
    );
  }

  async function remove() {
    if (deleteTarget === null) return;
    await bridge.unregisterGeofence({ id: deleteTarget.id });
    setItems(
      (current) => current?.filter((item) => item.id !== deleteTarget.id) ?? [],
    );
    setDeleteTarget(null);
  }

  return (
    <section className="feature-page" aria-labelledby="geofence-list-title">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">
            {t("geofence.list.eyebrow")}
          </span>
          <h1 id="geofence-list-title">{t("geofence.list.title")}</h1>
          <p>{t("geofence.list.description")}</p>
        </div>
        <Button onClick={() => navigate("/geofence/message")}>
          {t("geofence.list.add")}
        </Button>
      </header>

      <div className="feature-page__status-grid">
        <div className="feature-page__status-card">
          <span>{t("geofence.list.locationService")}</span>
          <strong>
            {locationEnabled === null
              ? t("common.loadingShort")
              : locationEnabled
                ? t("common.enabled")
                : t("common.disabled")}
          </strong>
        </div>
        <div className="feature-page__status-card">
          <span>{t("geofence.list.autoSend")}</span>
          <strong>
            {readiness === null
              ? t("common.loadingShort")
              : readiness.ready
                ? t("geofence.list.ready")
                : t("geofence.list.needsSetup", {
                    count: readiness.missing.length,
                  })}
          </strong>
        </div>
      </div>

      {readiness !== null && !readiness.ready ? (
        <div className="feature-page__banner" role="status">
          {t("geofence.list.permissionWarning")}{" "}
          <Link to="/user-permission">{t("geofence.list.openPermission")}</Link>
        </div>
      ) : null}
      {platform === "ios" && items !== null ? (
        <div className="feature-page__banner" role="status">
          {t("geofence.list.iosLimit", {
            count: items.filter((item) => item.active).length,
          })}
        </div>
      ) : null}
      <div className="feature-page__banner" role="note">
        {t("geofence.list.oneShotHint")}
      </div>
      {error === null ? null : (
        <p className="feature-page__error" role="alert">
          {error}{" "}
          <button onClick={() => void load()}>{t("common.retry")}</button>
        </p>
      )}

      {items === null ? (
        <LoadingState label={t("geofence.list.loading")} rows={3} />
      ) : items.length === 0 ? (
        <EmptyState
          icon="◎"
          title={t("geofence.list.emptyTitle")}
          description={t("geofence.list.emptyDescription")}
          actionLabel={t("geofence.list.add")}
          onAction={() => navigate("/geofence/message")}
        />
      ) : (
        <ul className="feature-page__list">
          {items.map((item) => (
            <li className="feature-page__list-card" key={item.id}>
              <div className="feature-page__row">
                <div>
                  <h2>{item.name}</h2>
                  <p>{item.address}</p>
                </div>
                <label className="feature-page__switch">
                  <input
                    type="checkbox"
                    checked={item.active}
                    onChange={(event) =>
                      void toggleActive(item, event.target.checked)
                    }
                  />
                  <span>
                    {item.active ? t("common.enabled") : t("common.disabled")}
                  </span>
                </label>
              </div>
              <div className="feature-page__meta">
                <span className="feature-page__chip">
                  {t(`geofence.event.${item.eventType}`)}
                </span>
                <span className="feature-page__chip">
                  {item.radiusMeters === 1000 ? "1km" : `${item.radiusMeters}m`}
                </span>
                <span className="feature-page__chip">
                  {t(`geofence.repeat.${item.repeatType}`)}
                </span>
              </div>
              {item.awaitingDeparture ? (
                <div className="feature-page__banner">
                  {t("geofence.list.awaitingDeparture")}
                </div>
              ) : null}
              <div className="feature-page__actions">
                <Button
                  variant="secondary"
                  onClick={() => navigate(`/geofence/${item.id}/edit`)}
                >
                  {t("common.edit")}
                </Button>
                <Button variant="danger" onClick={() => setDeleteTarget(item)}>
                  {t("common.delete")}
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}

      <BottomSheet
        open={deleteTarget !== null}
        title={t("geofence.list.deleteTitle")}
        onClose={() => setDeleteTarget(null)}
      >
        <p>
          {t("geofence.list.deleteDescription", {
            name: deleteTarget?.name ?? "",
          })}
        </p>
        <div className="feature-page__actions">
          <Button variant="secondary" onClick={() => setDeleteTarget(null)}>
            {t("common.cancel")}
          </Button>
          <Button variant="danger" onClick={() => void remove()}>
            {t("common.delete")}
          </Button>
        </div>
      </BottomSheet>
    </section>
  );
}
