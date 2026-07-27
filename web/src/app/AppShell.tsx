import { useEffect } from "react";
import { Outlet, useNavigate } from "react-router-dom";

import { useBridge } from "@/bridge/bridge-context";
import { normalizePushPath } from "@/pages/record/record-model";

export function AppShell() {
  const bridge = useBridge();
  const navigate = useNavigate();

  useEffect(
    () =>
      bridge.events.subscribe("onPushOpened", ({ path }) => {
        navigate(normalizePushPath(path));
      }),
    [bridge, navigate],
  );

  return (
    <div className="app-shell">
      <div className="app-shell__content">
        <Outlet />
      </div>
    </div>
  );
}
