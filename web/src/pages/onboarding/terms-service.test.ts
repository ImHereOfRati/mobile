import { describe, expect, it, vi } from "vitest";

import { activateWithTerms, type Term } from "./terms-service";

const terms: Term[] = [
  {
    id: 1,
    version: 3,
    type: "SERVICE",
    title: "필수 약관",
    content: "내용",
    effectiveDate: "2026-07-26",
    isRequired: true,
  },
  {
    id: 2,
    version: 2,
    type: "MARKETING",
    title: "선택 약관",
    content: "내용",
    effectiveDate: "2026-07-26",
    isRequired: false,
  },
];

describe("activateWithTerms", () => {
  it("matches the Flutter activation contract and includes declined terms", async () => {
    const activate = vi.fn().mockResolvedValue({});

    await activateWithTerms(
      { activateWithTerms: activate },
      terms,
      new Set([1]),
    );

    expect(activate).toHaveBeenCalledWith({
      consents: [
        { id: 1, agreed: true },
        { id: 2, agreed: false },
      ],
    });
  });
});
