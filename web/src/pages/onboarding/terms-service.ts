import type { ApiClient } from "@/api/api-client";

export interface Term {
  content: string;
  effectiveDate: string;
  id: number;
  isRequired: boolean;
  title: string;
  type: string;
  version: number;
}

export function loadTerms(api: ApiClient, signal?: AbortSignal) {
  return api.request<Term[]>("/api/terms?isActive=true", { signal });
}

export function activateWithTerms(
  api: ApiClient,
  terms: Term[],
  agreedIds?: ReadonlySet<number>,
) {
  return api.request("/api/auth/activation", {
    method: "POST",
    body: JSON.stringify({
      consents: terms.map((term) => ({
        id: term.id,
        agreed: agreedIds?.has(term.id) ?? true,
      })),
    }),
  });
}
