import { PlaceholderScreen } from "@/components/PlaceholderScreen";

type RecordScreen =
  | "overview"
  | "notifications"
  | "notificationDetail"
  | "friendRequests"
  | "sendHistory"
  | "sendHistoryDetail";

interface RecordPageProps {
  screen: RecordScreen;
}

export default function RecordPage({ screen }: RecordPageProps) {
  return <PlaceholderScreen titleKey={`screens.record.${screen}`} />;
}
