import type { ApiClient } from "@/api/api-client";

/**
 * 서버가 남기는 동의 이력 한 줄. 같은 약관에 대해 여러 줄이 쌓이므로,
 * "지금 동의 상태"는 termId별 가장 최근 줄의 action으로 판단한다.
 */
export interface AgreementHistoryEntry {
  action: "CONSENT" | "WITHDRAW";
  occurredAt: string;
  termId: number;
}

export interface TermConsentInput {
  agreed: boolean;
  id: number;
}

export const agreementService = {
  history(api: ApiClient, signal?: AbortSignal) {
    return api.request<AgreementHistoryEntry[]>("/api/agreements", { signal });
  },
  consent(api: ApiClient, consents: TermConsentInput[]) {
    return api.request<void>("/api/agreements", {
      method: "POST",
      body: JSON.stringify({ consents }),
    });
  },
  consentToRenewal(api: ApiClient, termId: number) {
    return api.request<void>(`/api/agreements/renewals/${termId}`, {
      method: "POST",
    });
  },
  withdraw(api: ApiClient, termId: number) {
    return api.request<void>(`/api/agreements/${termId}`, {
      method: "DELETE",
    });
  },
};

/** termId -> 가장 최근 이력. 서버가 순서를 보장하지 않아 시각으로 직접 고른다. */
export function toLatestByTerm(entries: AgreementHistoryEntry[]) {
  return entries.reduce<Map<number, AgreementHistoryEntry>>((latest, entry) => {
    const current = latest.get(entry.termId);
    if (current === undefined || entry.occurredAt > current.occurredAt) {
      latest.set(entry.termId, entry);
    }
    return latest;
  }, new Map());
}

export function isAgreed(entry: AgreementHistoryEntry | undefined) {
  return entry?.action === "CONSENT";
}
