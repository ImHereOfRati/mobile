import { useTranslation } from "react-i18next";
import { NavLink, Outlet } from "react-router-dom";

const tabs = [
  {
    path: "/geofence",
    labelKey: "navigation.geofence",
  },
  {
    path: "/friend",
    labelKey: "navigation.friend",
  },
  {
    path: "/record",
    labelKey: "navigation.record",
  },
  {
    path: "/setting",
    labelKey: "navigation.setting",
  },
] as const;

export function AppShell() {
  const { t } = useTranslation();

  return (
    <div className="app-shell">
      <main className="app-shell__content">
        <Outlet />
      </main>
      <nav className="app-shell__navigation" aria-label={t("navigation.label")}>
        {tabs.slice(0, 2).map((tab) => (
          <NavLink key={tab.path} to={tab.path}>
            {t(tab.labelKey)}
          </NavLink>
        ))}
        <NavLink
          className="app-shell__add"
          to="/geofence/message"
          aria-label={t("navigation.add")}
        >
          +
        </NavLink>
        {tabs.slice(2).map((tab) => (
          <NavLink key={tab.path} to={tab.path}>
            {t(tab.labelKey)}
          </NavLink>
        ))}
      </nav>
    </div>
  );
}
