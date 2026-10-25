import { lazy } from "react";
import {
  createBrowserRouter,
  Navigate,
  type RouteObject,
} from "react-router-dom";

import { AppRoot } from "@/app/AppRoot";
import { AppShell } from "@/app/AppShell";
import { NotFoundPage } from "@/app/NotFoundPage";
import { RouteErrorFallback } from "@/app/RouteErrorFallback";

const GeofencePage = lazy(() => import("@/pages/geofence/GeofencePage"));
const FriendPage = lazy(() => import("@/pages/friend/FriendPage"));
const RecordPage = lazy(() => import("@/pages/record/RecordPage"));
const AutoSendReadinessPage = lazy(
  () => import("@/pages/setting/AutoSendReadinessPage"),
);

export const appRoutes: RouteObject[] = [
  {
    element: <AppRoot />,
    errorElement: <RouteErrorFallback />,
    children: [
      {
        index: true,
        element: <Navigate replace to="/geofence" />,
      },
      {
        element: <AppShell />,
        children: [
          {
            path: "geofence",
            element: <GeofencePage screen="list" />,
          },
          {
            path: "geofence/message",
            element: <GeofencePage screen="message" />,
          },
          {
            path: "geofence/:geofenceId/edit",
            element: <GeofencePage screen="edit" />,
          },
          {
            path: "friend",
            element: <FriendPage screen="list" />,
          },
          {
            path: "friend/add",
            element: <FriendPage screen="add" />,
          },
          {
            path: "friend/requests",
            element: <FriendPage screen="requests" />,
          },
          {
            path: "friend/restrictions",
            element: <FriendPage screen="restrictions" />,
          },
          {
            path: "friend/device-contact/:contactId/edit",
            element: <FriendPage screen="deviceContactEdit" />,
          },
          {
            path: "record",
            element: <RecordPage screen="overview" />,
          },
          {
            path: "record/notifications",
            element: <RecordPage screen="notifications" />,
          },
          {
            path: "record/notifications/:recordId",
            element: <RecordPage screen="notificationDetail" />,
          },
          {
            path: "record/server-notifications",
            element: <RecordPage screen="serverNotifications" />,
          },
          {
            path: "record/friend-requests",
            element: <RecordPage screen="friendRequests" />,
          },
          {
            path: "record/send-history",
            element: <RecordPage screen="sendHistory" />,
          },
          {
            path: "record/send-history/:recordId",
            element: <RecordPage screen="sendHistoryDetail" />,
          },
          {
            path: "auto-send-readiness",
            element: <AutoSendReadinessPage />,
          },
        ],
      },
      {
        path: "*",
        element: <NotFoundPage />,
      },
    ],
  },
];

export function createAppRouter() {
  return createBrowserRouter(appRoutes, {
    basename: import.meta.env.BASE_URL.replace(/\/$/, ""),
  });
}
