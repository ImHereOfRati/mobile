import "@/pages/feature-page.css";

import { RecordDetailScreen } from "./RecordDetailScreen";
import { RecordFriendRequestScreen } from "./RecordFriendRequestScreen";
import { RecordOverviewScreen } from "./RecordOverviewScreen";
import { SendHistoryScreen } from "./SendHistoryScreen";
import { ServerNotificationScreen } from "./ServerNotificationScreen";

type RecordScreen =
  | "overview"
  | "notifications"
  | "notificationDetail"
  | "serverNotifications"
  | "friendRequests"
  | "sendHistory"
  | "sendHistoryDetail";

interface RecordPageProps {
  screen: RecordScreen;
}

export default function RecordPage({ screen }: RecordPageProps) {
  if (screen === "notifications") return <ServerNotificationScreen />;
  if (screen === "notificationDetail") {
    return <RecordDetailScreen kind="notification" />;
  }
  if (screen === "serverNotifications") return <ServerNotificationScreen />;
  if (screen === "friendRequests") return <RecordFriendRequestScreen />;
  if (screen === "sendHistory") return <SendHistoryScreen />;
  if (screen === "sendHistoryDetail") {
    return <RecordDetailScreen kind="record" />;
  }
  return <RecordOverviewScreen />;
}
