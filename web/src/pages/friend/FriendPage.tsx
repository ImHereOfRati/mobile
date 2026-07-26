import "@/pages/feature-page.css";

import { FriendAddScreen } from "./FriendAddScreen";
import { FriendListScreen } from "./FriendListScreen";
import { FriendRequestScreen } from "./FriendRequestScreen";
import { FriendRestrictionScreen } from "./FriendRestrictionScreen";

interface FriendPageProps {
  screen: "list" | "add" | "requests" | "restrictions";
}

export default function FriendPage({ screen }: FriendPageProps) {
  if (screen === "add") return <FriendAddScreen />;
  if (screen === "requests") return <FriendRequestScreen />;
  if (screen === "restrictions") return <FriendRestrictionScreen />;
  return <FriendListScreen />;
}
