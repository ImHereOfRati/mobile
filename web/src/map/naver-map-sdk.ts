let sdkPromise: Promise<void> | undefined;

export function loadNaverMapSdk(clientId: string): Promise<void> {
  if (globalThis.window.naver?.maps !== undefined) return Promise.resolve();
  if (!/^[a-zA-Z0-9_-]+$/.test(clientId)) {
    return Promise.reject(new Error("Invalid Naver map client id"));
  }

  sdkPromise ??= new Promise<void>((resolve, reject) => {
    const script = document.createElement("script");
    script.async = true;
    script.src =
      "https://oapi.map.naver.com/openapi/v3/maps.js" +
      `?ncpKeyId=${encodeURIComponent(clientId)}`;
    script.addEventListener("load", () => resolve(), { once: true });
    script.addEventListener(
      "error",
      () => reject(new Error("Naver map SDK failed to load")),
      { once: true },
    );
    document.head.append(script);
  });
  return sdkPromise;
}
