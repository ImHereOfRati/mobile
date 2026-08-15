const me = {
  id: "me",
  email: "dongsu@example.com",
  nickname: "동수",
  oAuth2Provider: "KAKAO",
};

const friend = {
  id: "friend-1",
  email: "mom@example.com",
  nickname: "엄마",
  oAuth2Provider: "KAKAO",
};

const friendship = {
  id: "relationship-1",
  friendAlias: "엄마",
  friend,
  owner: me,
  createdAt: "2026-07-27T08:00:00Z",
  updatedAt: "2026-07-27T08:00:00Z",
};

const friendRequest = {
  id: "request-1",
  message: "ImHere에서 친구가 되어 주세요.",
  requester: {
    id: "friend-2",
    email: "minsu@example.com",
    nickname: "민수",
    oAuth2Provider: "KAKAO",
  },
  receiver: me,
  createdAt: "2026-07-27T08:30:00Z",
  updatedAt: "2026-07-27T08:30:00Z",
};

function envelope(data: unknown) {
  return JSON.stringify({
    imhereResponseCode: "SUCCESS",
    message: "ok",
    data,
  });
}

export const browserPreviewFetch: typeof fetch = async (input, init) => {
  const url = new URL(
    typeof input === "string"
      ? input
      : input instanceof URL
        ? input
        : input.url,
  );
  const method = init?.method?.toUpperCase() ?? "GET";
  let data: unknown = null;

  if (url.pathname === "/api/terms") {
    data = [
      {
        id: 1,
        title: "서비스 이용약관",
        content: "ImHere 서비스 이용에 필요한 기본 약관입니다.",
        effectiveDate: "2026-07-01",
        isRequired: true,
        type: "SERVICE",
        version: 1,
      },
    ];
  } else if (url.pathname === "/api/users/my") {
    data =
      method === "PATCH"
        ? {
            ...me,
            nickname:
              JSON.parse(String(init?.body ?? "{}")).nickname ?? me.nickname,
          }
        : me;
  } else if (url.pathname === "/api/friendships") {
    data = { content: [friendship], hasNext: false };
  } else if (/^\/api\/friendships\/[^/]+\/alias$/.test(url.pathname)) {
    data = friendship;
  } else if (url.pathname === "/api/friends/requests") {
    data =
      method === "POST"
        ? { friendRequestId: "request-preview" }
        : { content: [friendRequest], hasNext: false };
  } else if (url.pathname === "/api/friends/restrictions") {
    data = {
      content: [
        {
          id: "restriction-1",
          type: "BLOCK",
          restricted: friend,
          restrictor: me,
          createdAt: "2026-07-27T07:00:00Z",
          updatedAt: "2026-07-27T07:00:00Z",
        },
      ],
      hasNext: false,
    };
  } else if (url.pathname === "/api/users") {
    data = { content: [friend], hasNext: false };
  }

  return new Response(envelope(data), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};
