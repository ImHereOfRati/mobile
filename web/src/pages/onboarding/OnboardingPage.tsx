import "./onboarding.css";

import AuthPage from "./AuthPage";
import PermissionGuidePage from "./PermissionGuidePage";
import PermissionPage from "./PermissionPage";
import TermDetailPage from "./TermDetailPage";
import TermsConsentPage from "./TermsConsentPage";

type OnboardingScreen =
  | "auth"
  | "termsConsent"
  | "termsDetail"
  | "userPermission"
  | "locationPermissionGuide"
  | "batteryOptimizationGuide";

interface OnboardingPageProps {
  screen: OnboardingScreen;
}

export default function OnboardingPage({ screen }: OnboardingPageProps) {
  switch (screen) {
    case "auth":
      return <AuthPage />;
    case "termsConsent":
      return <TermsConsentPage />;
    case "termsDetail":
      return <TermDetailPage />;
    case "userPermission":
      return <PermissionPage />;
    case "locationPermissionGuide":
      return <PermissionGuidePage kind="location" />;
    case "batteryOptimizationGuide":
      return <PermissionGuidePage kind="battery" />;
  }
}
