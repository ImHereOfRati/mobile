import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { Button, LoadingState } from "@/design-system";

import { loadTerms, type Term } from "./terms-service";

export default function TermDetailPage() {
  const api = useApiClient();
  const navigate = useNavigate();
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
          <LoadingState label="약관을 불러오는 중" />
        ) : error ? (
          <p className="onboarding__error" role="alert">
            약관을 찾을 수 없습니다.
          </p>
        ) : (
          <>
            <header className="onboarding__header">
              <h1 id="term-title">{term?.title}</h1>
              <p className="onboarding__meta">시행일 {term?.effectiveDate}</p>
            </header>
            <div className="onboarding__content">{term?.content}</div>
          </>
        )}
        <Button variant="secondary" onClick={() => navigate(-1)}>
          돌아가기
        </Button>
      </article>
    </main>
  );
}
