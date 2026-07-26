import { useParams } from "react-router-dom";

interface GeofencePageProps {
  screen: "edit" | "list" | "message";
}

export default function GeofencePage({ screen }: GeofencePageProps) {
  const { geofenceId } = useParams();
  if (screen === "list") return <GeofenceListScreen />;
  return (
    <GeofenceFormScreen
      id={screen === "edit" ? Number(geofenceId) : undefined}
    />
  );
}

import { GeofenceFormScreen } from "./GeofenceFormScreen";
import { GeofenceListScreen } from "./GeofenceListScreen";
import "../feature-page.css";
