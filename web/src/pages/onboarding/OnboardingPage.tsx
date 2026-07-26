import { PlaceholderScreen } from "@/components/PlaceholderScreen";

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
  return <PlaceholderScreen titleKey={`screens.onboarding.${screen}`} />;
}
