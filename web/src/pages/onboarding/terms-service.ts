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

export function activateWithTerms(api: ApiClient, terms: Term[]) {
  return api.request("/api/auth/activation", {
    method: "POST",
    body: JSON.stringify({
      consents: terms.map((term) => ({
        termId: term.id,
        termVersion: term.version,
        agreed: true,
      })),
    }),
  });
}
