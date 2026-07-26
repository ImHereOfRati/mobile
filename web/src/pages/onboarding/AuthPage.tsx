import { useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { Button } from "@/design-system";

const slides = [
  [
    "도착하면 자동으로 알려드려요",
    "장소와 사람을 정하면 ImHere가 자동 전송을 준비해요.",
  ],
  [
    "앱이 꺼져도 놓치지 않아요",
    "네이티브 지오펜스가 백그라운드에서 계속 동작해요.",
  ],
  [
    "내 정보는 기기에 안전하게",
    "로그인과 권한은 앱에서 처리하고 웹에는 필요한 정보만 전달해요.",
  ],
] as const;

export default function AuthPage() {
  const bridge = useBridge();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const [step, setStep] = useState(0);
  const [loading, setLoading] = useState<"kakao" | "google" | null>(null);
  const [error, setError] = useState<string | null>(
    params.get("reason") === "inactive"
      ? "비활성화된 계정입니다. 도움이 필요하면 고객센터에 문의해 주세요."
      : null,
  );
  const [title, description] = slides[step];

  async function signIn(provider: "kakao" | "google") {
    setLoading(provider);
    setError(null);
    try {
      const session =
        provider === "kakao"
          ? await bridge.signInWithKakao()
          : await bridge.signInWithGoogle();
      if (session.authState.userStatus === "inactive") {
        setError("비활성화된 계정입니다.");
        return;
      }
      navigate(
        session.authState.userStatus === "pending"
          ? "/terms-consent"
          : "/user-permission",
        { replace: true },
      );
    } catch {
      setError("로그인하지 못했습니다. 잠시 후 다시 시도해 주세요.");
    } finally {
      setLoading(null);
    }
  }

  return (
    <main className="onboarding">
      <section className="onboarding__panel" aria-labelledby="auth-title">
        <header className="onboarding__header">
          <p className="onboarding__eyebrow">ImHere 시작하기</p>
          <h1 id="auth-title">{title}</h1>
          <p className="onboarding__description">{description}</p>
        </header>
        <div className="onboarding__steps" aria-label="소개 단계">
          {slides.map((slide, index) => (
            <button
              key={slide[0]}
              className="onboarding__step"
              aria-label={`${index + 1}단계`}
              aria-current={index === step ? "step" : undefined}
              onClick={() => setStep(index)}
            />
          ))}
        </div>
        {step < slides.length - 1 ? (
          <Button onClick={() => setStep((current) => current + 1)}>
            다음
          </Button>
        ) : (
          <div className="onboarding__actions">
            <Button
              loading={loading === "kakao"}
              onClick={() => void signIn("kakao")}
            >
              카카오로 계속하기
            </Button>
            <Button
              variant="secondary"
              loading={loading === "google"}
              onClick={() => void signIn("google")}
            >
              Google로 계속하기
            </Button>
          </div>
        )}
        <p className="onboarding__notice">
          계속하면 서비스 이용약관과 개인정보 처리방침을 확인하고 동의하는
          단계로 이동합니다.
        </p>
        {error === null ? null : (
          <p className="onboarding__error" role="alert">
            {error}
          </p>
        )}
      </section>
    </main>
  );
}
