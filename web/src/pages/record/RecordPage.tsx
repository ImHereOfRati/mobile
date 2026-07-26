import "@/pages/feature-page.css";

import { NotificationListScreen } from "./NotificationListScreen";
import { RecordDetailScreen } from "./RecordDetailScreen";
import { RecordFriendRequestScreen } from "./RecordFriendRequestScreen";
import { RecordOverviewScreen } from "./RecordOverviewScreen";
import { SendHistoryScreen } from "./SendHistoryScreen";

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
  if (screen === "notifications") return <NotificationListScreen />;
  if (screen === "notificationDetail") {
    return <RecordDetailScreen kind="notification" />;
  }
  if (screen === "friendRequests") return <RecordFriendRequestScreen />;
  if (screen === "sendHistory") return <SendHistoryScreen />;
  if (screen === "sendHistoryDetail") {
    return <RecordDetailScreen kind="record" />;
  }
  return <RecordOverviewScreen />;
}
