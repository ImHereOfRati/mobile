import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { Button, LoadingState } from "@/design-system";

import { loadTerms, type Term } from "./terms-service";

export default function TermDetailPage() {
  const api = useApiClient();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { termId } = useParams();
  const [term, setTerm] = useState<Term | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    void loadTerms(api, controller.signal)
      .then((terms) => {
        const found = terms.find((item) => String(item.id) === termId);
        if (found === undefined) setError(true);
        else setTerm(found);
      })
      .catch(() => setError(true));
    return () => controller.abort();
  }, [api, termId]);

  return (
    <main className="onboarding">
      <article className="onboarding__panel" aria-labelledby="term-title">
        {term === null && !error ? (
          <LoadingState label={t("onboarding.termDetail.loading")} />
        ) : error ? (
          <p className="onboarding__error" role="alert">
            {t("onboarding.termDetail.notFound")}
          </p>
        ) : (
          <>
            <header className="onboarding__header">
              <h1 id="term-title">{term?.title}</h1>
              <p className="onboarding__meta">
                {t("onboarding.termDetail.effectiveDate", {
                  date: term?.effectiveDate,
                })}
              </p>
            </header>
            <div className="onboarding__content">{term?.content}</div>
          </>
        )}
        <Button variant="secondary" onClick={() => navigate(-1)}>
          {t("onboarding.termDetail.back")}
        </Button>
      </article>
    </main>
  );
}
