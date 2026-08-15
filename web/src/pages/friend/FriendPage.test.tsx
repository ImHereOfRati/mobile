import { createMockBridge } from "@imhere/bridge-contract";
import { fireEvent, render, screen, within } from "@testing-library/react";
import axe from "axe-core";
import { MemoryRouter } from "react-router-dom";
import { afterEach, describe, expect, it, vi } from "vitest";

import { BridgeProvider } from "@/bridge/BridgeProvider";

import FriendPage from "./FriendPage";

const envelope = (data: unknown) =>
  JSON.stringify({ imhereResponseCode: "SUCCESS", message: "ok", data });

afterEach(() => vi.unstubAllGlobals());

describe("FriendPage", () => {
  it("merges server friends with device contacts and has no accessibility violations", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async (input: URL | RequestInfo) => {
        const url = new URL(String(input));
        if (url.pathname === "/api/users") {
          return new Response(
            envelope({
              content: [
                {
                  id: "search-result-1",
                  nickname: "민지",
                  email: "minji@example.com",
                },
              ],
              hasNext: false,
            }),
          );
        }
        if (url.pathname === "/api/friends/requests") {
          return new Response(
            envelope({ friendRequestId: "friend-request-1" }),
          );
        }
        if (url.pathname === "/api/friendships/relationship-1") {
          return new Response(
            envelope({
              id: "relationship-1",
              friendAlias: "엄마",
              friend: {
                id: "friend-1",
                email: "mom@example.com",
                nickname: "어머니",
                oAuth2Provider: "KAKAO",
              },
              owner: {
                id: "me",
                email: "me@example.com",
                nickname: "나",
                oAuth2Provider: "KAKAO",
              },
              createdAt: "2026-07-26T00:00:00Z",
              updatedAt: "2026-07-26T00:00:00Z",
            }),
          );
        }
        // 검색 결과의 관계 상태 조회. 아직 친구도 아니고 차단하지도 않은 상대다.
        if (
          url.pathname.startsWith("/api/friendships/target/") ||
          url.pathname.startsWith("/api/friends/restrictions/target/")
        ) {
          return new Response(envelope(false));
        }
        return new Response(
          envelope({
            content: [
              {
                id: "relationship-1",
                friendAlias: "엄마",
                friend: {
                  id: "friend-1",
                  email: "mom@example.com",
                  nickname: "어머니",
                  oAuth2Provider: "KAKAO",
                },
                owner: {
                  id: "me",
                  email: "me@example.com",
                  nickname: "나",
                  oAuth2Provider: "KAKAO",
                },
                createdAt: "2026-07-26T00:00:00Z",
                updatedAt: "2026-07-26T00:00:00Z",
              },
            ],
            hasNext: false,
          }),
        );
      }),
    );
    const controller = createMockBridge({
      getDeviceContacts: async () => [
        {
          id: "contact-1",
          displayName: "회사",
          phoneNumbers: ["010-1234-5678"],
        },
      ],
      getAccessToken: async () => ({ accessToken: "token" }),
    });
    const { container } = render(
      <BridgeProvider bridge={controller.bridge}>
        <MemoryRouter>
          <FriendPage screen="list" />
        </MemoryRouter>
      </BridgeProvider>,
    );

    expect(await screen.findByRole("heading", { name: "엄마" })).toBeVisible();
    expect(screen.getByRole("heading", { name: "회사" })).toBeVisible();

    fireEvent.click(screen.getByRole("button", { name: "새로운 친구 찾기" }));
    const finder = screen.getByRole("dialog", { name: "친구 찾기" });
    expect(finder).toBeVisible();
    expect(
      screen.getByRole("textbox", { name: "닉네임 또는 이메일" }),
    ).toBeVisible();
    expect(
      screen.queryByRole("textbox", { name: "요청 메시지" }),
    ).not.toBeInTheDocument();

    fireEvent.change(
      screen.getByRole("textbox", { name: "닉네임 또는 이메일" }),
      { target: { value: "민지" } },
    );
    fireEvent.click(screen.getByRole("button", { name: "검색" }));
    fireEvent.click(await screen.findByRole("button", { name: "선택" }));
    expect(screen.getByRole("textbox", { name: "요청 메시지" })).toBeVisible();
    expect(screen.getByText("minji@example.com")).toBeVisible();

    fireEvent.click(
      within(finder).getByRole("button", { name: "바텀시트 닫기" }),
    );

    fireEvent.click(screen.getByRole("button", { name: "엄마 더보기" }));
    expect(screen.getByRole("dialog", { name: "엄마" })).toBeVisible();
    expect((await axe.run(container)).violations).toEqual([]);
  });
});
