export interface ImHereEnvelope<T> {
  data: T;
  imhereResponseCode: string;
  message: string;
}

export interface SliceResponse<T> {
  content: T[];
  hasNext: boolean;
}

export interface AccessTokenProvider {
  getAccessToken(): Promise<{ accessToken: string | null }>;
  refreshAccessToken(): Promise<{ accessToken: string | null }>;
}

export interface ApiRequestOptions extends RequestInit {
  apiVersion?: number;
  timeoutMs?: number;
}

export class ApiHttpError extends Error {
  constructor(
    readonly status: number,
    readonly responseBody: unknown,
  ) {
    super(`API request failed with status ${status}`);
    this.name = "ApiHttpError";
  }
}

type Fetch = typeof globalThis.fetch;

export class ApiClient {
  private refreshInFlight: Promise<string | null> | undefined;

  constructor(
    private readonly baseUrl: string,
    private readonly tokens: AccessTokenProvider,
    private readonly fetchImpl: Fetch = globalThis.fetch.bind(globalThis),
  ) {}

  async request<T>(path: string, options: ApiRequestOptions = {}): Promise<T> {
    const { signal, cleanup } = createRequestSignal(
      options.signal,
      options.timeoutMs ?? 10_000,
    );
    try {
      return await this.execute<T>(path, options, signal, false);
    } finally {
      cleanup();
    }
  }

  private async execute<T>(
    path: string,
    options: ApiRequestOptions,
    signal: AbortSignal,
    retried: boolean,
  ): Promise<T> {
    // Native WebView bridges can briefly be unavailable while Flutter
    // restores its session. A missing token must not prevent the request from
    // being issued; the server response can still be handled normally.
    const token = (await this.tokens
      .getAccessToken()
      .catch(() => ({ accessToken: null }))) ?? { accessToken: null };
    const response = await this.fetchImpl(
      buildApiUrl(this.baseUrl, path, options.apiVersion ?? 1),
      {
        ...options,
        signal,
        headers: {
          Accept: "application/json",
          ...(options.body === undefined
            ? {}
            : { "Content-Type": "application/json" }),
          ...options.headers,
          ...(token.accessToken === null
            ? {}
            : { Authorization: `Bearer ${token.accessToken}` }),
        },
      },
    );

    if (response.status === 401 && !retried) {
      const refreshed = await this.refreshOnce();
      if (refreshed !== null) {
        return this.execute<T>(path, options, signal, true);
      }
    }

    const body = await readBody(response);
    if (!response.ok) throw new ApiHttpError(response.status, body);
    // 서버는 동의 변경·철회·차단 해제처럼 돌려줄 것이 없는 요청에 204를 낸다.
    // 봉투가 아예 없는 응답이므로 unwrapEnvelope에 넘기면 성공한 요청에서 던진다.
    if (body === undefined) return undefined as T;
    return unwrapEnvelope<T>(body);
  }

  private refreshOnce() {
    this.refreshInFlight ??= this.tokens
      .refreshAccessToken()
      .then(({ accessToken }) => accessToken)
      .finally(() => {
        this.refreshInFlight = undefined;
      });
    return this.refreshInFlight;
  }
}

export function unwrapEnvelope<T>(value: unknown): T {
  if (
    typeof value !== "object" ||
    value === null ||
    !("imhereResponseCode" in value) ||
    !("message" in value) ||
    !("data" in value)
  ) {
    throw new TypeError("Invalid ImHere API response envelope");
  }
  return (value as ImHereEnvelope<T>).data;
}

export function nextSlicePageParam<T>(
  lastPage: SliceResponse<T>,
  pages: SliceResponse<T>[],
) {
  return lastPage.hasNext ? pages.length : undefined;
}

function buildApiUrl(baseUrl: string, path: string, apiVersion: number) {
  const url = new URL(path, baseUrl);
  url.searchParams.set("v", String(apiVersion));
  return url;
}

async function readBody(response: Response) {
  const text = await response.text();
  if (text.length === 0) return undefined;
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return text;
  }
}

function createRequestSignal(
  parent: AbortSignal | null | undefined,
  timeoutMs: number,
) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("timeout"), timeoutMs);
  const abort = () => controller.abort(parent?.reason);
  parent?.addEventListener("abort", abort, { once: true });
  if (parent?.aborted === true) abort();

  return {
    signal: controller.signal,
    cleanup() {
      clearTimeout(timeout);
      parent?.removeEventListener("abort", abort);
    },
  };
}
