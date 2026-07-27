export interface NativeShellChannel {
  postMessage(message: string): void;
}

declare global {
  interface Window {
    ImHereShell?: NativeShellChannel;
    __imhereNavigate?: (path: string) => void;
  }
}

export function getNativePageTitle(path: string) {
  if (path === "/" || path === "/auth") return "ImHere";
  if (path === "/terms-consent") return "약관 동의";
  if (path.startsWith("/terms-detail/")) return "약관 상세";
  if (path === "/user-permission") return "권한 설정";
  if (path === "/location-permission-guide") return "위치 권한 안내";
  if (path === "/battery-optimization-guide") return "배터리 설정 안내";
  if (path === "/catalog") return "디자인 시스템";
  if (path === "/geofence/message") return "장소 추가";
  if (/^\/geofence\/[^/]+\/edit$/.test(path)) return "장소 수정";
  if (path.startsWith("/geofence")) return "장소";
  if (path === "/friend/add") return "친구 추가";
  if (path === "/friend/requests") return "친구 요청";
  if (path === "/friend/restrictions") return "차단·거절 관리";
  if (path.startsWith("/friend")) return "친구";
  if (/^\/record\/notifications\/[^/]+$/.test(path)) {
    return "받은 알림 상세";
  }
  if (path === "/record/notifications") return "받은 알림";
  if (path === "/record/friend-requests") return "친구 요청 기록";
  if (/^\/record\/send-history\/[^/]+$/.test(path)) return "전송 기록 상세";
  if (path === "/record/send-history") return "전송 기록";
  if (path.startsWith("/record")) return "기록";
  if (path === "/setting") return "설정";
  return "ImHere";
}

export function notifyNativeShell(path: string) {
  window.ImHereShell?.postMessage(
    JSON.stringify({
      path,
      title: getNativePageTitle(path),
    }),
  );
}
