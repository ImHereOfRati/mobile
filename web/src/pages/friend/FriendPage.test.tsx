import { createMockBridge } from "@imhere/bridge-contract";
import { render, screen } from "@testing-library/react";
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
      vi.fn(
        async () =>
          new Response(
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
          ),
      ),
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
    expect((await axe.run(container)).violations).toEqual([]);
  });
});
