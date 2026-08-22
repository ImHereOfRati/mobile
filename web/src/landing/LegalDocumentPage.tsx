import { useEffect, useState, type ReactNode } from "react";

type LegalTermType = "PRIVACY" | "SERVICE";

interface Term {
  content: string;
  effectiveDate: string;
  title: string;
  type: string;
  version: number;
}

export function LegalDocumentPage({ type }: { type: LegalTermType }) {
  const [term, setTerm] = useState<Term>();
  const [error, setError] = useState(false);

  useEffect(() => {
    const controller = new AbortController();
    const apiOrigin =
      import.meta.env.VITE_API_BASE_URL || window.location.origin;
    const url = new URL("/api/terms", apiOrigin);
    url.searchParams.set("isActive", "true");
    url.searchParams.set("v", "1");

    void fetch(url, { signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error("Terms request failed");
        const body = (await response.json()) as { data?: Term[] };
        const next = body.data?.find((item) => item.type === type);
        if (!next) throw new Error("Term not found");
        setTerm(next);
      })
      .catch((reason: unknown) => {
        if (reason instanceof DOMException && reason.name === "AbortError")
          return;
        setError(true);
      });

    return () => controller.abort();
  }, [type]);

  return (
    <DocumentShell title={term?.title ?? "문서"}>
      {term === undefined && !error ? (
        <p className="legal-document__status" role="status">
          문서를 불러오는 중입니다.
        </p>
      ) : error ? (
        <p className="legal-document__status" role="alert">
          문서를 불러오지 못했습니다.
        </p>
      ) : (
        <>
          <p className="privacy-policy__updated">
            {formatDate(term!.effectiveDate)} · v{term!.version}
          </p>
          <div className="privacy-policy__sections">
            {splitSections(term!.content).map((section, index) => (
              <details key={`${section.heading}-${index}`} open={index === 0}>
                <summary>{section.heading}</summary>
                <p>{section.body}</p>
              </details>
            ))}
          </div>
        </>
      )}
    </DocumentShell>
  );
}

function DocumentShell({
  children,
  title,
}: {
  children: ReactNode;
  title: string;
}) {
  return (
    <div className="landing legal-document">
      <header className="topbar">
        <a className="brand" href="/" aria-label="ImHere 홈">
          <strong>ImHere</strong>
        </a>
        <nav className="topbar__nav" aria-label="법적 문서">
          <a href="/?document=privacy">개인정보처리방침</a>
          <a href="/?document=terms">서비스 약관</a>
        </nav>
      </header>
      <main className="privacy-policy">
        <div className="privacy-policy__inner">
          <p className="eyebrow">ImHere 문서</p>
          <h1>{title}</h1>
          {children}
        </div>
      </main>
    </div>
  );
}

function splitSections(content: string) {
  return content
    .split(/\n(?=\d+\.\s)/)
    .map((section) => section.trim())
    .filter(Boolean)
    .map((section) => {
      const lineBreak = section.indexOf("\n");
      if (lineBreak < 0) return { body: "", heading: section };
      return {
        heading: section.slice(0, lineBreak).trim(),
        body: section.slice(lineBreak + 1).trim(),
      };
    });
}

function formatDate(value: string) {
  return new Intl.DateTimeFormat("ko-KR", { dateStyle: "long" }).format(
    new Date(value),
  );
}
