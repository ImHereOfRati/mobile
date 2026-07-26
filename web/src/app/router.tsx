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

const OnboardingPage = lazy(() => import("@/pages/onboarding/OnboardingPage"));
const ComponentCatalogPage = lazy(
  () => import("@/pages/catalog/ComponentCatalogPage"),
);
const GeofencePage = lazy(() => import("@/pages/geofence/GeofencePage"));
const FriendPage = lazy(() => import("@/pages/friend/FriendPage"));
const RecordPage = lazy(() => import("@/pages/record/RecordPage"));
const SettingPage = lazy(() => import("@/pages/setting/SettingPage"));

export const appRoutes: RouteObject[] = [
  {
    element: <AppRoot />,
    errorElement: <RouteErrorFallback />,
    children: [
      {
        index: true,
        element: <Navigate replace to="/auth" />,
      },
      {
        path: "auth",
        element: <OnboardingPage screen="auth" />,
      },
      {
        path: "terms-consent",
        element: <OnboardingPage screen="termsConsent" />,
      },
      {
        path: "terms-detail/:termId",
        element: <OnboardingPage screen="termsDetail" />,
      },
      {
        path: "user-permission",
        element: <OnboardingPage screen="userPermission" />,
      },
      {
        path: "location-permission-guide",
        element: <OnboardingPage screen="locationPermissionGuide" />,
      },
      {
        path: "battery-optimization-guide",
        element: <OnboardingPage screen="batteryOptimizationGuide" />,
      },
      {
        path: "catalog",
        element: <ComponentCatalogPage />,
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
            path: "setting",
            element: <SettingPage />,
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
    basename: "/app",
  });
}
