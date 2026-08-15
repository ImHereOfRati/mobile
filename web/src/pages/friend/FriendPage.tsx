import "@/pages/feature-page.css";

import { FriendListScreen } from "./FriendListScreen";
import { FriendRequestScreen } from "./FriendRequestScreen";
import { FriendRestrictionScreen } from "./FriendRestrictionScreen";
import { DeviceContactEditScreen } from "./DeviceContactEditScreen";
import { useParams } from "react-router-dom";

interface FriendPageProps {
  screen: "list" | "add" | "requests" | "restrictions" | "deviceContactEdit";
}

export default function FriendPage({ screen }: FriendPageProps) {
  const { contactId } = useParams();
  if (screen === "add") return <FriendListScreen finderInitiallyOpen />;
  if (screen === "requests") return <FriendRequestScreen />;
  if (screen === "restrictions") return <FriendRestrictionScreen />;
  if (screen === "deviceContactEdit") {
    return <DeviceContactEditScreen contactId={contactId} />;
  }
  return <FriendListScreen />;
}
