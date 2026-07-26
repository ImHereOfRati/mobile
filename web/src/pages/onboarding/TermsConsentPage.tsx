import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { Button, LoadingState } from "@/design-system";

import { activateWithTerms, loadTerms, type Term } from "./terms-service";

export default function TermsConsentPage() {
  const api = useApiClient();
  const navigate = useNavigate();
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
          await activateWithTerms(api, []);
          navigate("/user-permission", { replace: true });
        }
      })
      .catch((reason: unknown) => {
        if ((reason as { name?: string }).name !== "AbortError") {
          setError("약관을 불러오지 못했습니다.");
        }
      });
    return () => controller.abort();
  }, [api, navigate]);

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
      await activateWithTerms(
        api,
        terms,
        agreed,
      );
      navigate("/user-permission", { replace: true });
    } catch {
      setError("동의 내용을 저장하지 못했습니다.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="terms-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">약관 동의</p>
          <h1 id="terms-title">ImHere 이용을 위해 확인해 주세요</h1>
          <p className="onboarding__description">
            선택 항목은 동의하지 않아도 서비스를 이용할 수 있어요.
          </p>
        </header>
        {terms === null && error === null ? (
          <LoadingState label="약관을 불러오는 중" />
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
                <strong>전체 동의</strong>
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
                  {term.isRequired ? "[필수]" : "[선택]"} {term.title}
                </span>
                <Link to={`/terms-detail/${term.id}`}>보기</Link>
              </label>
            ))}
          </div>
        )}
        <Button
          disabled={!requiredAgreed}
          loading={submitting}
          onClick={() => void submit()}
        >
          동의하고 계속하기
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
