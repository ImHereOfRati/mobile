import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link, useNavigate } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import { Button, LoadingState } from "@/design-system";

import { activateWithTerms, loadTerms, type Term } from "./terms-service";

export default function TermsConsentPage() {
  const api = useApiClient();
  const bridge = useBridge();
  const { setConsent, track } = useAnalytics();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [terms, setTerms] = useState<Term[] | null>(null);
  const [agreed, setAgreed] = useState<Set<number>>(new Set());
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const requiredIds = useMemo(
    () => terms?.filter((term) => term.isRequired).map((term) => term.id) ?? [],
    [terms],
  );
  const allAgreed =
    terms !== null && terms.length > 0 && agreed.size === terms.length;
  const requiredAgreed = requiredIds.every((id) => agreed.has(id));

  useEffect(() => {
    const controller = new AbortController();
    void loadTerms(api, controller.signal)
      .then(async (loaded) => {
        setTerms(loaded);
        if (loaded.length === 0) {
          await activateWithTerms(bridge, []);
          await setConsent(false);
          await track("terms_accepted", {
            optional_count: 0,
            required_count: 0,
          });
          navigate("/user-permission", { replace: true });
        }
      })
      .catch((reason: unknown) => {
        if ((reason as { name?: string }).name !== "AbortError") {
          setError(t("onboarding.termsConsent.loadFailed"));
        }
      });
    return () => controller.abort();
  }, [api, bridge, navigate, setConsent, t, track]);

  function toggle(id: number) {
    setAgreed((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function submit() {
    if (terms === null || !requiredAgreed) return;
    setSubmitting(true);
    try {
      await activateWithTerms(bridge, terms, agreed);
      const analyticsConsent = terms.some(
        (term) => term.type === "MARKETING" && agreed.has(term.id),
      );
      await setConsent(analyticsConsent);
      await track("terms_accepted", {
        optional_count: terms.filter(
          (term) => !term.isRequired && agreed.has(term.id),
        ).length,
        required_count: requiredIds.length,
      });
      navigate("/user-permission", { replace: true });
    } catch {
      setError(t("onboarding.termsConsent.saveFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="terms-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">
            {t("onboarding.termsConsent.eyebrow")}
          </p>
          <h1 id="terms-title">{t("onboarding.termsConsent.title")}</h1>
          <p className="onboarding__description">
            {t("onboarding.termsConsent.description")}
          </p>
        </header>
        {terms === null && error === null ? (
          <LoadingState label={t("onboarding.termsConsent.loading")} />
        ) : (
          <div className="onboarding__list">
            {terms !== null && terms.length > 0 ? (
              <label className="onboarding__term">
                <input
                  type="checkbox"
                  checked={allAgreed}
                  onChange={() =>
                    setAgreed(
                      allAgreed
                        ? new Set()
                        : new Set(terms.map((term) => term.id)),
                    )
                  }
                />
                <strong>{t("onboarding.termsConsent.all")}</strong>
              </label>
            ) : null}
            {terms?.map((term) => (
              <label key={term.id} className="onboarding__term">
                <input
                  type="checkbox"
                  checked={agreed.has(term.id)}
                  onChange={() => toggle(term.id)}
                />
                <span>
                  [
                  {term.isRequired
                    ? t("onboarding.termsConsent.required")
                    : t("onboarding.termsConsent.optional")}
                  ] {term.title}
                </span>
                <Link to={`/terms-detail/${term.id}`}>
                  {t("onboarding.termsConsent.view")}
                </Link>
              </label>
            ))}
          </div>
        )}
        <Button
          disabled={!requiredAgreed}
          loading={submitting}
          onClick={() => void submit()}
        >
          {t("onboarding.termsConsent.submit")}
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
