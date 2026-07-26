import { PlaceholderScreen } from "@/components/PlaceholderScreen";

interface FriendPageProps {
  screen: "list" | "add" | "requests" | "restrictions";
}

export default function FriendPage({ screen }: FriendPageProps) {
  return <PlaceholderScreen titleKey={`screens.friend.${screen}`} />;
}
