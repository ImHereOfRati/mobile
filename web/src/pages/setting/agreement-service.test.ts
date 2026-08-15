import { describe, expect, it, vi } from "vitest";

import type { ApiClient } from "@/api/api-client";

import {
  agreementService,
  type AgreementHistoryEntry,
  isAgreed,
  toLatestByTerm,
} from "./agreement-service";

const entry = (
  termId: number,
  action: AgreementHistoryEntry["action"],
  occurredAt: string,
): AgreementHistoryEntry => ({ termId, action, occurredAt });

describe("toLatestByTerm", () => {
  it("keeps the newest entry per term regardless of arrival order", () => {
    const latest = toLatestByTerm([
      entry(1, "CONSENT", "2026-07-01T00:00:00"),
      entry(1, "WITHDRAW", "2026-08-01T00:00:00"),
      entry(1, "CONSENT", "2026-06-01T00:00:00"),
      entry(2, "CONSENT", "2026-07-15T00:00:00"),
    ]);

    expect(latest.get(1)?.action).toBe("WITHDRAW");
    expect(latest.get(2)?.action).toBe("CONSENT");
  });

  it("treats a withdrawn or missing term as not agreed", () => {
    expect(isAgreed(entry(1, "WITHDRAW", "2026-08-01T00:00:00"))).toBe(false);
    expect(isAgreed(undefined)).toBe(false);
    expect(isAgreed(entry(1, "CONSENT", "2026-08-01T00:00:00"))).toBe(true);
  });
});

describe("agreementService", () => {
  it("sends consent changes in the shape the server validates", async () => {
    const request = vi.fn().mockResolvedValue(undefined);
    const api = { request } as unknown as ApiClient;

    await agreementService.consent(api, [{ id: 2, agreed: true }]);

    expect(request).toHaveBeenCalledWith("/api/agreements", {
      method: "POST",
      body: JSON.stringify({ consents: [{ id: 2, agreed: true }] }),
    });
  });

  it("addresses renewal and withdrawal by term id", async () => {
    const request = vi.fn().mockResolvedValue(undefined);
    const api = { request } as unknown as ApiClient;

    await agreementService.consentToRenewal(api, 7);
    await agreementService.withdraw(api, 7);

    expect(request.mock.calls[0]?.[0]).toBe("/api/agreements/renewals/7");
    expect(request.mock.calls[1]?.[0]).toBe("/api/agreements/7");
    expect(request.mock.calls[1]?.[1]).toEqual({ method: "DELETE" });
  });
});
