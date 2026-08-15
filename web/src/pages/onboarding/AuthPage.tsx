import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useSearchParams } from "react-router-dom";

import { useAnalytics } from "@/analytics/analytics-context";
import { useBridge } from "@/bridge/bridge-context";
import { Button } from "@/design-system";

export default function AuthPage() {
  const bridge = useBridge();
  const analytics = useAnalytics();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const { t } = useTranslation();
  const slides = [
    [t("onboarding.auth.slides.location.title"), null],
    [
      t("onboarding.auth.slides.background.title"),
      t("onboarding.auth.slides.background.description"),
    ],
    [
      t("onboarding.auth.slides.privacy.title"),
      t("onboarding.auth.slides.privacy.description"),
    ],
  ] as const;
  const [step, setStep] = useState(0);
  const [loading, setLoading] = useState<"kakao" | "google" | null>(null);
  const [error, setError] = useState<string | null>(
    params.get("reason") === "inactive"
      ? t("onboarding.auth.inactiveWithSupport")
      : null,
  );
  const [title, description] = slides[step];

  async function signIn(provider: "kakao" | "google") {
    setLoading(provider);
    setError(null);
    await analytics.track("login_started", { provider });
    try {
      const session =
        provider === "kakao"
          ? await bridge.signInWithKakao()
          : await bridge.signInWithGoogle();
      if (session.authState.userStatus === "inactive") {
        setError(t("onboarding.auth.inactive"));
        return;
      }
      if (session.authState.userStatus === "active") {
        await analytics.setConsent(true);
      }
      await analytics.track("login_completed", { provider });
      navigate(
        session.authState.userStatus === "pending"
          ? "/terms-consent"
          : "/user-permission",
        { replace: true },
      );
    } catch {
      await analytics.track("login_failed", { provider });
      setError(t("onboarding.auth.signInFailed"));
    } finally {
      setLoading(null);
    }
  }

  return (
    <main className="onboarding">
      <section
        className="onboarding__panel onboarding__panel--centered"
        aria-labelledby="auth-title"
      >
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">{t("onboarding.auth.eyebrow")}</p>
          <h1 id="auth-title">{title}</h1>
          {description === null ? null : (
            <p className="onboarding__description">{description}</p>
          )}
        </header>
        <div
          className="onboarding__steps"
          aria-label={t("onboarding.auth.stepsLabel")}
        >
          {slides.map((slide, index) => (
            <button
              key={slide[0]}
              className="onboarding__step"
              aria-label={t("onboarding.auth.stepLabel", { step: index + 1 })}
              aria-current={index === step ? "step" : undefined}
              onClick={() => setStep(index)}
            />
          ))}
        </div>
        {step < slides.length - 1 ? (
          <Button onClick={() => setStep((current) => current + 1)}>
            {t("onboarding.auth.next")}
          </Button>
        ) : (
          <div className="onboarding__actions">
            <Button
              loading={loading === "kakao"}
              onClick={() => void signIn("kakao")}
            >
              {t("onboarding.auth.kakao")}
            </Button>
            <Button
              variant="secondary"
              loading={loading === "google"}
              onClick={() => void signIn("google")}
            >
              {t("onboarding.auth.google")}
            </Button>
          </div>
        )}
        {error === null ? null : (
          <p className="onboarding__error" role="alert">
            {error}
          </p>
        )}
      </section>
    </main>
  );
}
