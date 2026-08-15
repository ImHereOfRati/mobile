import type { BridgeMethodResult } from "@imhere/bridge-contract";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate } from "react-router-dom";

import { useAnalytics } from "@/analytics/analytics-context";
import { useApiClient } from "@/api/use-api-client";
import { useBridge } from "@/bridge/bridge-context";
import {
  BottomSheet,
  Button,
  EmptyState,
  FlatListRow,
  LoadingState,
  MoreButton,
  ToggleSwitch,
} from "@/design-system";
import { MapProxyService } from "@/map/map-proxy-service";

import type { Geofence } from "./geofence-model";
import {
  fillMissingGeofenceAddresses,
  loadGeofences,
} from "./geofence-service";

export function GeofenceListScreen() {
  const { t } = useTranslation();
  const bridge = useBridge();
  const api = useApiClient();
  const mapService = useMemo(() => new MapProxyService(api), [api]);
  const analytics = useAnalytics();
  const navigate = useNavigate();
  const [items, setItems] = useState<Geofence[] | null>(null);
  const [readiness, setReadiness] =
    useState<BridgeMethodResult<"getAutoSendReadiness"> | null>(null);
  const [locationEnabled, setLocationEnabled] = useState<boolean | null>(null);
  const [platform, setPlatform] =
    useState<BridgeMethodResult<"getAppInfo">["platform"]>("browser");
  const [error, setError] = useState<string | null>(null);
  const [actionTarget, setActionTarget] = useState<Geofence | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Geofence | null>(null);

  const load = useCallback(async () => {
    const [geofences, autoSend, location, appInfo] = await Promise.allSettled([
      loadGeofences(bridge),
      bridge.getAutoSendReadiness(),
      bridge.getLocationServiceStatus(),
      bridge.getAppInfo(),
    ]);
    if (geofences.status === "fulfilled") {
      const hydrated = await fillMissingGeofenceAddresses(
        bridge,
        mapService,
        geofences.value,
      );
      setItems(hydrated);
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
  }, [bridge, mapService, t]);

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

  useEffect(() => {
    if (items?.some((item) => item.active) !== true) return;
    const interval = globalThis.setInterval(() => {
      void loadGeofences(bridge).then(setItems);
    }, 5_000);
    return () => globalThis.clearInterval(interval);
  }, [bridge, items]);

  async function toggleActive(item: Geofence, active: boolean) {
    const updated = await bridge.setGeofenceActive({ id: item.id, active });
    await analytics.track("geofence_toggled", { active });
    setItems(
      (current) =>
        current?.map((value) => (value.id === updated.id ? updated : value)) ??
        [],
    );
  }

  async function remove() {
    if (deleteTarget === null) return;
    await bridge.unregisterGeofence({ id: deleteTarget.id });
    await analytics.track("geofence_deleted", {
      event_type: deleteTarget.eventType,
    });
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
      </header>

      <div className="feature-page__status-grid">
        <div className="feature-page__status-card">
          <StatusIcon kind="location" />
          <div>
            <span>{t("geofence.list.locationService")}</span>
            <strong
              className={
                locationEnabled === false ? "status-needs-action" : ""
              }
            >
              {locationEnabled === null
                ? t("common.loadingShort")
                : locationEnabled
                  ? t("common.enabled")
                  : t("common.disabled")}
            </strong>
          </div>
        </div>
        <div className="feature-page__status-card">
          <StatusIcon kind="auto-send" />
          <div>
            <span>{t("geofence.list.autoSend")}</span>
            <strong>
            {readiness === null ? (
              t("common.loadingShort")
            ) : readiness.ready ? (
              t("geofence.list.ready")
            ) : (
              <>
                <span
                  className={
                    readiness.missing.length > 0
                      ? "auto-send-missing-count"
                      : undefined
                  }
                >
                  {readiness.missing.length}개
                </span>{" "}
                설정 필요
              </>
            )}
            </strong>
          </div>
        </div>
      </div>

      {readiness !== null && !readiness.ready ? (
        <div className="feature-page__banner" role="status">
          {t("geofence.list.permissionWarning")}{" "}
          <Link to="/auto-send-readiness">
            {t("geofence.list.openPermission")}
          </Link>
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
        <ul className="feature-page__list" data-clarity-mask="true">
          {items.map((item) => (
            <FlatListRow
              element="li"
              key={item.id}
              title={item.name}
              titleAs="h2"
              description={item.address}
              detail={formatGeofenceCondition(item)}
              status={
                item.awaitingDeparture
                  ? t("geofence.list.awaitingDeparture")
                  : undefined
              }
              onClick={() => navigate(`/geofence/${item.id}/edit`)}
              actions={
                <>
                  <MoreButton
                    label={`${item.name} 더보기`}
                    onClick={() => setActionTarget(item)}
                  />
                  <ToggleSwitch
                    label={`${item.name} ${
                      item.active ? t("common.enabled") : t("common.disabled")
                    }`}
                    checked={item.active}
                    onChange={(active) => void toggleActive(item, active)}
                  />
                </>
              }
            />
          ))}
        </ul>
      )}

      <BottomSheet
        open={actionTarget !== null}
        title={actionTarget?.name ?? ""}
        onClose={() => setActionTarget(null)}
      >
        <div className="feature-page__sheet-actions">
          <Button
            variant="secondary"
            onClick={() => {
              if (actionTarget !== null) {
                navigate(`/geofence/${actionTarget.id}/edit`);
              }
            }}
          >
            {t("common.edit")}
          </Button>
          <Button
            variant="danger"
            onClick={() => {
              setDeleteTarget(actionTarget);
              setActionTarget(null);
            }}
          >
            {t("common.delete")}
          </Button>
        </div>
      </BottomSheet>

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

function StatusIcon({ kind }: { kind: "location" | "auto-send" }) {
  return (
    <span
      className={`feature-page__status-icon feature-page__status-icon--${kind}`}
      aria-hidden="true"
    >
      {kind === "location" ? (
        <svg viewBox="0 0 24 24" focusable="false">
          <path d="M12 21s7-6.2 7-12a7 7 0 1 0-14 0c0 5.8 7 12 7 12Z" />
          <circle cx="12" cy="9" r="2.25" />
        </svg>
      ) : (
        <svg viewBox="0 0 24 24" focusable="false">
          <path d="M12 3.5 19 6v5.2c0 4.2-2.8 7.7-7 9.3-4.2-1.6-7-5.1-7-9.3V6l7-2.5Z" />
          <path d="m8.8 12 2.1 2.1 4.4-4.4" />
        </svg>
      )}
    </span>
  );
}

function formatGeofenceCondition(item: Geofence) {
  const radius = item.radiusMeters === 1000 ? "1km" : `${item.radiusMeters}m`;
  if (item.eventType === "arrival") return `${radius} 내 진입 시`;
  if (item.eventType === "departure") return `${radius} 밖으로 나갈 시`;
  return `${radius} 경계 진입·이탈 시`;
}
