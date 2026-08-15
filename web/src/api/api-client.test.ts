import { describe, expect, it, vi } from "vitest";

import { ApiClient, nextSlicePageParam, unwrapEnvelope } from "./api-client";

const envelope = (data: unknown) =>
  JSON.stringify({ imhereResponseCode: "SUCCESS", message: "ok", data });

describe("ApiClient", () => {
  it("unwraps the response envelope and appends ?v=1", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      void input;
      return new Response(envelope({ id: 7 }));
    });
    const client = new ApiClient(
      "https://api.example/",
      {
        getAccessToken: async () => ({ accessToken: "token" }),
        refreshAccessToken: async () => ({ accessToken: "new-token" }),
      },
      fetchMock,
    );

    await expect(client.request<{ id: number }>("/api/items")).resolves.toEqual(
      {
        id: 7,
      },
    );
    expect(String(fetchMock.mock.calls[0]?.[0])).toBe(
      "https://api.example/api/items?v=1",
    );
  });

  it("resolves to undefined when the server answers 204", async () => {
    const fetchMock = vi.fn(async (input: RequestInfo | URL) => {
      void input;
      return new Response(null, { status: 204 });
    });
    const client = new ApiClient(
      "https://api.example/",
      {
        getAccessToken: async () => ({ accessToken: "token" }),
        refreshAccessToken: async () => ({ accessToken: "new-token" }),
      },
      fetchMock,
    );

    await expect(
      client.request<void>("/api/agreements/1", { method: "DELETE" }),
    ).resolves.toBeUndefined();
  });

  it("serializes concurrent 401 refreshes and retries once", async () => {
    let refreshed = false;
    const refreshAccessToken = vi.fn(async () => {
      await Promise.resolve();
      refreshed = true;
      return { accessToken: "new-token" };
    });
    const fetchMock = vi.fn(
      async (input: RequestInfo | URL, init?: RequestInit) => {
        void input;
        void init;
        return refreshed
          ? new Response(envelope({ ok: true }))
          : new Response("unauthorized", { status: 401 });
      },
    );
    const client = new ApiClient(
      "https://api.example/",
      {
        getAccessToken: async () => ({
          accessToken: refreshed ? "new-token" : "old-token",
        }),
        refreshAccessToken,
      },
      fetchMock,
    );

    await expect(
      Promise.all([client.request("/a"), client.request("/b")]),
    ).resolves.toEqual([{ ok: true }, { ok: true }]);
    expect(refreshAccessToken).toHaveBeenCalledTimes(1);
  });

  it("supports caller cancellation", async () => {
    const controller = new AbortController();
    const client = new ApiClient(
      "https://api.example/",
      {
        getAccessToken: async () => ({ accessToken: null }),
        refreshAccessToken: async () => ({ accessToken: null }),
      },
      (_input, init) =>
        new Promise((_resolve, reject) => {
          if (init?.signal?.aborted === true) {
            reject(new DOMException("Aborted", "AbortError"));
            return;
          }
          init?.signal?.addEventListener("abort", () =>
            reject(new DOMException("Aborted", "AbortError")),
          );
        }),
    );

    const request = client.request("/slow", { signal: controller.signal });
    controller.abort();
    await expect(request).rejects.toMatchObject({ name: "AbortError" });
  });
});

describe("API response helpers", () => {
  it("rejects malformed envelopes", () => {
    expect(() => unwrapEnvelope({ data: 1 })).toThrow(TypeError);
  });

  it("returns the next slice index only when hasNext is true", () => {
    expect(
      nextSlicePageParam({ content: [], hasNext: true }, [
        { content: [], hasNext: true },
      ]),
    ).toBe(1);
    expect(
      nextSlicePageParam({ content: [], hasNext: false }, []),
    ).toBeUndefined();
  });
});
