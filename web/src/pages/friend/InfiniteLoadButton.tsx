import { useCallback, useEffect, useRef, useState } from "react";

interface InfiniteLoadButtonProps {
  hasNext: boolean;
  label: string;
  load: () => Promise<void>;
}

export function InfiniteLoadButton({
  hasNext,
  label,
  load,
}: InfiniteLoadButtonProps) {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const [loading, setLoading] = useState(false);

  const run = useCallback(async () => {
    if (loading || !hasNext) return;
    setLoading(true);
    try {
      await load();
    } finally {
      setLoading(false);
    }
  }, [hasNext, load, loading]);

  useEffect(() => {
    const button = buttonRef.current;
    if (!hasNext || button === null || !("IntersectionObserver" in window)) {
      return;
    }
    const observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) void run();
    });
    observer.observe(button);
    return () => observer.disconnect();
    // Observer is renewed after each page and loading transition.
  }, [hasNext, run]);

  if (!hasNext) return null;
  return (
    <button
      aria-busy={loading}
      className="ds-button ds-button--secondary"
      disabled={loading}
      onClick={() => void run()}
      ref={buttonRef}
      type="button"
    >
      {label}
    </button>
  );
}
