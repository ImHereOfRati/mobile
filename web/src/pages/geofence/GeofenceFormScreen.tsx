import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import {
  BottomSheet,
  Button,
  LoadingState,
  TextField,
  ToggleSwitch,
} from "@/design-system";
import { MapProxyService } from "@/map/map-proxy-service";
import {
  NaverLocationPicker,
  type MapSelection,
} from "@/map/NaverLocationPicker";

import {
  defaultGeofenceDraft,
  draftFromGeofence,
  type EventType,
  type GeofenceDraft,
  type RecipientOption,
  toBridgeInput,
  validateGeofenceDraft,
} from "./geofence-model";
import { findGeofence, loadRecipientOptions } from "./geofence-service";

const eventTypes: EventType[] = ["arrival", "departure"];

export function GeofenceFormScreen({ id }: { id?: number }) {
  const { t } = useTranslation();
  const bridge = useBridge();
  const analytics = useAnalytics();
  const api = useApiClient();
  const navigate = useNavigate();
  const mapService = useMemo(() => new MapProxyService(api), [api]);
  const [draft, setDraft] = useState<GeofenceDraft | null>(null);
  const [recipients, setRecipients] = useState<RecipientOption[]>([]);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void bridge
      .getAutoSendReadiness()
      .then(async (readiness) => {
        if (cancelled) return;
        if (!readiness.locationAlways) {
          navigate("/auto-send-readiness?returnTo=%2Fgeofence%2Fmessage", {
            replace: true,
          });
          return;
        }
        return Promise.all([
          loadRecipientOptions(api, bridge),
          id === undefined
            ? bridge.getCurrentPosition()
            : findGeofence(bridge, id),
        ]);
      })
      .then((result) => {
        if (cancelled || result === undefined) return;
        const [options, source] = result;
        setRecipients(options);
        if (id === undefined) {
          const position = source as Awaited<
            ReturnType<typeof bridge.getCurrentPosition>
          >;
          setDraft({
            ...defaultGeofenceDraft,
            latitude: position.latitude,
            longitude: position.longitude,
          });
        } else if (source !== undefined && "radiusMeters" in source) {
          setDraft(draftFromGeofence(source));
        } else {
          setLoadError(t("geofence.form.notFound"));
        }
      })
      .catch(() => {
        if (!cancelled) setLoadError(t("geofence.form.loadError"));
      });
    return () => {
      cancelled = true;
    };
  }, [api, bridge, id, navigate, t]);

  const update = useCallback(
    <Key extends keyof GeofenceDraft>(key: Key, value: GeofenceDraft[Key]) => {
      setDraft((current) =>
        current === null ? current : { ...current, [key]: value },
      );
      setErrors((current) => ({ ...current, [key]: "" }));
    },
    [],
  );

  const updateMap = useCallback((selection: MapSelection) => {
    setDraft((current) =>
      current === null
        ? current
        : {
            ...current,
            address: selection.address ?? current.address,
            latitude: selection.latitude,
            longitude: selection.longitude,
            name: selection.name ?? current.name,
            radiusMeters: selection.radiusMeters,
          },
    );
  }, []);

  function toggleRecipient(option: RecipientOption) {
    if (draft === null) return;
    if (option.source === "device") {
      const next = new Set(draft.deviceContactIds);
      if (next.has(option.key)) next.delete(option.key);
      else next.add(option.key);
      update("deviceContactIds", next);
    } else {
      const next = new Set(draft.serverRecipientKeys);
      if (next.has(option.key)) next.delete(option.key);
      else next.add(option.key);
      update("serverRecipientKeys", next);
    }
    setErrors((current) => ({ ...current, recipients: "" }));
  }

  async function submit() {
    if (draft === null) return;
    const nextErrors = validateGeofenceDraft(draft);
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;
    setSaving(true);
    try {
      await bridge.registerGeofence(toBridgeInput(draft, recipients));
      await analytics.track("geofence_saved", {
        event_type: draft.eventType,
        mode: id === undefined ? "create" : "edit",
      });
      setSaved(true);
    } catch {
      setErrors({ submit: t("geofence.form.saveError") });
    } finally {
      setSaving(false);
    }
  }

  if (loadError !== null) {
    return (
      <section className="feature-page">
        <p className="feature-page__error" role="alert">
          {loadError}
        </p>
      </section>
    );
  }
  if (draft === null) {
    return (
      <section className="feature-page">
        <LoadingState label={t("geofence.form.loading")} rows={5} />
      </section>
    );
  }

  const selection: MapSelection = {
    address: draft.address,
    latitude: draft.latitude,
    longitude: draft.longitude,
    name: draft.name,
    radiusMeters: draft.radiusMeters,
  };
  const hasDeviceRecipients = draft.deviceContactIds.size > 0;

  return (
    <section className="feature-page" aria-labelledby="geofence-form-title">
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">
            {t("geofence.form.eyebrow")}
          </span>
          <h1 id="geofence-form-title">
            {id === undefined
              ? t("geofence.form.createTitle")
              : t("geofence.form.editTitle")}
          </h1>
        </div>
      </header>

      <form
        className="feature-form"
        data-clarity-mask="true"
        onSubmit={(event) => {
          event.preventDefault();
          void submit();
        }}
      >
        <section className="feature-form__section">
          <h2>{t("geofence.form.location")}</h2>
          <NaverLocationPicker
            clientId={import.meta.env.VITE_NAVER_MAP_CLIENT_ID || "browser"}
            value={selection}
            onChange={updateMap}
            searchPlaces={(query, signal) =>
              mapService.searchPlaces(query, signal)
            }
          />
          {errors.address === undefined ||
          errors.address.length === 0 ? null : (
            <p className="feature-page__error" role="alert">
              {errors.address}
            </p>
          )}
        </section>

        <section className="feature-form__section">
          <h2>{t("geofence.form.details")}</h2>
          <TextField
            label={t("geofence.form.name")}
            value={draft.name}
            error={errors.name || undefined}
            onChange={(event) => update("name", event.target.value)}
          />
          <TextField
            label={t("geofence.form.address")}
            value={draft.address}
            readOnly
            error={errors.address || undefined}
          />
          <TextField
            label={t("geofence.form.message")}
            value={draft.message}
            error={errors.message || undefined}
            disabled={hasDeviceRecipients}
            helperText={
              hasDeviceRecipients
                ? "기기 연락처 알림은 장소 이름이 자동으로 적용됩니다."
                : "{location}은 장소 이름으로 치환됩니다."
            }
            onChange={(event) => update("message", event.target.value)}
          />
        </section>

        <fieldset className="feature-form__section">
          <legend>{t("geofence.form.event")}</legend>
          <div className="feature-form__options">
            {eventTypes.map((eventType) => (
              <label className="feature-form__option" key={eventType}>
                <input
                  type="radio"
                  name="eventType"
                  value={eventType}
                  checked={draft.eventType === eventType}
                  onChange={() => update("eventType", eventType)}
                />
                {t(`geofence.event.${eventType}`)}
              </label>
            ))}
          </div>
        </fieldset>

        <section className="feature-form__section">
          <div className="feature-page__section-header">
            <div>
              <h2>{t("geofence.form.recipients")}</h2>
              <p>{t("geofence.form.recipientDescription")}</p>
            </div>
            <span className="feature-page__chip">
              {draft.deviceContactIds.size + draft.serverRecipientKeys.size}
            </span>
          </div>
          <ul className="feature-form__recipients">
            {recipients.map((recipient) => {
              const checked =
                recipient.source === "device"
                  ? draft.deviceContactIds.has(recipient.key)
                  : draft.serverRecipientKeys.has(recipient.key);
              return (
                <li key={`${recipient.source}:${recipient.key}`}>
                  <label className="feature-form__recipient">
                    <input
                      type="checkbox"
                      checked={checked}
                      onChange={() => toggleRecipient(recipient)}
                    />
                    <span>
                      <strong>{recipient.label}</strong>
                      <small>
                        {recipient.description} ·{" "}
                        {t(`geofence.recipient.${recipient.source}`)}
                      </small>
                    </span>
                  </label>
                </li>
              );
            })}
          </ul>
          {errors.recipients === undefined ||
          errors.recipients.length === 0 ? null : (
            <p className="feature-page__error" role="alert">
              {errors.recipients}
            </p>
          )}
        </section>

        <div className="feature-page__toggle-row">
          <span>{t("geofence.form.activateImmediately")}</span>
          <ToggleSwitch
            checked={draft.active}
            label={t("geofence.form.activateImmediately")}
            onChange={(active) => update("active", active)}
          />
        </div>

        {errors.submit === undefined ? null : (
          <p className="feature-page__error" role="alert">
            {errors.submit}
          </p>
        )}
        <Button loading={saving} type="submit">
          {id === undefined
            ? t("geofence.form.create")
            : t("geofence.form.save")}
        </Button>
      </form>

      <BottomSheet
        open={saved}
        title={t("geofence.form.completeTitle")}
        onClose={() => navigate("/geofence")}
      >
        <p>{t("geofence.form.completeDescription", { name: draft.name })}</p>
        <Button onClick={() => navigate("/geofence")}>
          {t("common.confirm")}
        </Button>
      </BottomSheet>
    </section>
  );
}
