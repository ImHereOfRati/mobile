import type { NativeBridge } from "@imhere/bridge-contract";

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
  bridge: Pick<NativeBridge, "activateWithTerms">,
  terms: Term[],
  agreedIds?: ReadonlySet<number>,
) {
  return bridge.activateWithTerms({
    consents: terms.map((term) => ({
      id: term.id,
      agreed: agreedIds?.has(term.id) ?? true,
    })),
  });
}
