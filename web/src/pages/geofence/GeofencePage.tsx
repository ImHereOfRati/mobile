import { PlaceholderScreen } from "@/components/PlaceholderScreen";

interface GeofencePageProps {
  screen: "list" | "message";
}

export default function GeofencePage({ screen }: GeofencePageProps) {
  return <PlaceholderScreen titleKey={`screens.geofence.${screen}`} />;
}
