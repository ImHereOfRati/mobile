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

export function formatDeliveryStatus(status: string) {
  const labels: Record<string, string> = {
    completed: "완료",
    failed: "실패",
    pending: "대기 중",
  };
  return labels[status] ?? status;
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
