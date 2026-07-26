import type { BridgeMethodResult } from "@imhere/bridge-contract";

export type DeliveryRecord =
  BridgeMethodResult<"queryRecords">["items"][number];
export type NativeNotification =
  BridgeMethodResult<"queryNotifications">["items"][number];

export function formatActivityTime(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat("ko-KR", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

export function normalizePushPath(path: string) {
  const trimmed = path.trim();
  const normalized = trimmed.startsWith("/app/")
    ? trimmed.slice(4)
    : trimmed === "/app"
      ? "/record"
      : trimmed;
  if (
    !normalized.startsWith("/") ||
    normalized.startsWith("//") ||
    normalized.includes("\\") ||
    normalized.includes(":")
  ) {
    return "/record";
  }
  return normalized;
}
