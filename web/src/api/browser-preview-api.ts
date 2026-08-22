const me = {
  id: "me",
  email: "dongsu@example.com",
  nickname: "?숈닔",
  oAuth2Provider: "KAKAO",
};

const friend = {
  id: "friend-1",
  email: "mom@example.com",
  nickname: "?꾨쭏",
  oAuth2Provider: "KAKAO",
};

const friendship = {
  id: "relationship-1",
  friendAlias: "?꾨쭏",
  friend,
  owner: me,
  createdAt: "2026-07-27T08:00:00Z",
  updatedAt: "2026-07-27T08:00:00Z",
};

const friendRequest = {
  id: "request-1",
  message: "ImHere?먯꽌 移쒓뎄媛 ?섏뼱 二쇱꽭??",
  requester: {
    id: "friend-2",
    email: "minsu@example.com",
    nickname: "誘쇱닔",
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

  if (url.pathname === "/api/users/my") {
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
