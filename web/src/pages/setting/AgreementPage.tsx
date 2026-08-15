import "@/pages/feature-page.css";

import { useEffect, useState } from "react";
import { Link } from "react-router-dom";

import { useApiClient } from "@/api/use-api-client";
import { loadTerms, type Term } from "@/pages/onboarding/terms-service";

import {
  agreementService,
  type AgreementHistoryEntry,
  isAgreed,
  toLatestByTerm,
} from "./agreement-service";

/**
 * 약관이 개정되면 시행일이 마지막 동의 시각보다 뒤로 간다. 그때는 기존 동의가
 * 더 이상 현재 약관에 대한 동의가 아니므로 재동의를 받아야 한다.
 */
function needsRenewal(term: Term, latest: AgreementHistoryEntry | undefined) {
  if (latest === undefined || !isAgreed(latest)) return false;
  return term.effectiveDate > latest.occurredAt;
}

export default function AgreementPage() {
  const api = useApiClient();
  const [terms, setTerms] = useState<Term[]>([]);
  const [latestByTerm, setLatestByTerm] = useState(
    new Map<number, AgreementHistoryEntry>(),
  );
  const [status, setStatus] = useState("동의 내역을 불러오는 중입니다.");

  const load = async (signal?: AbortSignal) => {
    try {
      const [termList, history] = await Promise.all([
        loadTerms(api, signal),
        agreementService.history(api, signal),
      ]);
      setTerms(termList);
      setLatestByTerm(toLatestByTerm(history));
      setStatus(termList.length === 0 ? "표시할 약관이 없습니다." : "");
    } catch {
      setStatus("동의 내역을 불러오지 못했습니다.");
    }
  };

  useEffect(() => {
    const controller = new AbortController();
    const initialLoad = globalThis.setTimeout(
      () => void load(controller.signal),
      0,
    );
    return () => {
      globalThis.clearTimeout(initialLoad);
      controller.abort();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api]);

  // 동의·철회·재동의 모두 서버가 이력을 새로 쌓기 때문에, 성공하면 목록을
  // 다시 읽어 화면 상태를 서버 이력에 맞춘다.
  const run = async (action: () => Promise<unknown>, message: string) => {
    try {
      await action();
      await load();
      setStatus(message);
    } catch {
      setStatus("동의 상태를 변경하지 못했습니다.");
    }
  };

  const agree = (term: Term) =>
    run(
      () => agreementService.consent(api, [{ id: term.id, agreed: true }]),
      `${term.title}에 동의했습니다.`,
    );

  const withdraw = (term: Term) => {
    if (!window.confirm(`${term.title} 동의를 철회할까요?`)) return;
    void run(
      () => agreementService.withdraw(api, term.id),
      `${term.title} 동의를 철회했습니다.`,
    );
  };

  const renew = (term: Term) =>
    run(
      () => agreementService.consentToRenewal(api, term.id),
      `개정된 ${term.title}에 다시 동의했습니다.`,
    );

  return (
    <main className="feature-page" data-clarity-mask="true">
      <Link className="feature-page__back" to="/setting">
        ← 설정
      </Link>
      <header className="feature-page__header">
        <div>
          <span className="feature-page__eyebrow">계정</span>
          <h1>약관 동의 관리</h1>
          <p>동의한 약관을 확인하고 선택 약관의 동의를 변경할 수 있습니다.</p>
        </div>
      </header>
      {status && <p aria-live="polite">{status}</p>}
      <ul className="feature-page__list">
        {terms.map((term) => {
          const latest = latestByTerm.get(term.id);
          const agreed = isAgreed(latest);
          const renewalRequired = needsRenewal(term, latest);
          return (
            <li className="feature-page__list-card" key={term.id}>
              <div className="feature-page__row">
                <div>
                  <h2>{term.title}</h2>
                  <p>
                    {agreed
                      ? `${latest?.occurredAt.slice(0, 10)} 동의`
                      : "동의하지 않음"}
                    {` · v${term.version}`}
                  </p>
                </div>
                <span className="feature-page__chip">
                  {term.isRequired ? "필수" : "선택"}
                </span>
              </div>
              <div className="feature-page__row">
                <Link
                  className="ds-button ds-button--secondary"
                  to={`/terms-detail/${term.id}`}
                >
                  약관 보기
                </Link>
                {renewalRequired && (
                  <button
                    className="ds-button"
                    onClick={() => void renew(term)}
                    type="button"
                  >
                    개정 약관 재동의
                  </button>
                )}
                {!agreed && (
                  <button
                    className="ds-button"
                    onClick={() => void agree(term)}
                    type="button"
                  >
                    동의하기
                  </button>
                )}
                {agreed && !term.isRequired && (
                  <button
                    className="ds-button ds-button--danger"
                    onClick={() => withdraw(term)}
                    type="button"
                  >
                    동의 철회
                  </button>
                )}
              </div>
              {agreed && term.isRequired && (
                <p className="setting-note">
                  필수 약관은 서비스 이용에 필요해 철회할 수 없습니다. 회원
                  탈퇴로만 동의를 거둘 수 있습니다.
                </p>
              )}
            </li>
          );
        })}
      </ul>
    </main>
  );
}
