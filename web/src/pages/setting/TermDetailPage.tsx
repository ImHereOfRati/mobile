import "./setting.css";
import "@/pages/feature-page.css";

import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { loadTerms, type Term } from "./terms-service";

export default function TermDetailPage() {
  const api = useApiClient();
  const { termId } = useParams();
  const [term, setTerm] = useState<Term>();
  const [error, setError] = useState<string>();
  const invalidTermId = !Number.isInteger(Number(termId));

  useEffect(() => {
    const id = Number(termId);
    if (invalidTermId) return;

    const controller = new AbortController();
    void loadTerms(api, controller.signal)
      .then((items) => {
        const found = items.find((item) => item.id === id);
        if (found === undefined) setError("약관을 찾을 수 없습니다.");
        else setTerm(found);
      })
      .catch((cause: unknown) => {
        if (!controller.signal.aborted) {
          setError(
            cause instanceof Error
              ? cause.message
              : "약관을 불러오지 못했습니다.",
          );
        }
      });

    return () => controller.abort();
  }, [api, invalidTermId, termId]);

  return (
    <main className="feature-page" data-clarity-mask="true">
      {term === undefined ? (
        <p aria-live="polite">
          {invalidTermId
            ? "약관을 찾을 수 없습니다."
            : (error ?? "약관을 불러오는 중입니다.")}
        </p>
      ) : (
        <article className="setting-term-detail">
          <span className="feature-page__eyebrow">
            {term.isRequired ? "필수 약관" : "선택 약관"}
          </span>
          <h1>{term.title}</h1>
          <p className="setting-term-detail__meta">
            버전 {term.version} · 시행일 {term.effectiveDate}
          </p>
          <div className="setting-term-detail__content">{term.content}</div>
        </article>
      )}
    </main>
  );
}
