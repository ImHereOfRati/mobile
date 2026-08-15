import { expect, test } from "@playwright/test";

test("keeps reverse-geocoded place, address, and notification message in sync", async ({
  page,
}) => {
  await page.addInitScript(() => {
    window.ImHereBridge = {} as typeof window.ImHereBridge;
  });
  await page.route("**/api/maps/reverse-geocode**", (route) => {
    const url = new URL(route.request().url());
    const latitude = url.searchParams.get("latitude");
    const isSearchResult = latitude === "37.57";
    return route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        imhereResponseCode: "SUCCESS",
        message: "ok",
        data: {
          results: [
            {
              name: isSearchResult ? "검색된 장소" : "서울시청",
              region: {
                area1: { name: "서울특별시" },
                area2: { name: "중구" },
              },
              land: {
                name: "세종대로",
                number1: isSearchResult ? "120" : "110",
              },
            },
          ],
        },
      }),
    });
  });
  await page.route("**/api/maps/local-search**", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        imhereResponseCode: "SUCCESS",
        message: "ok",
        data: {
          items: [
            {
              title: "검색 결과 title",
              roadAddress: "서울특별시 중구 세종대로 120",
            },
          ],
        },
      }),
    }),
  );
  await page.route("**/api/maps/geocode**", (route) =>
    route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        imhereResponseCode: "SUCCESS",
        message: "ok",
        data: {
          addresses: [
            {
              roadAddress: "서울특별시 중구 세종대로 120",
              x: "126.99",
              y: "37.57",
            },
          ],
        },
      }),
    }),
  );

  await page.goto("geofence/message");
  const placeName = page.getByRole("textbox", {
    name: "장소 이름",
    exact: true,
  });
  const address = page.getByRole("textbox", { name: "주소", exact: true });
  const message = page
    .locator("label")
    .filter({ hasText: "알림 메시지" })
    .locator("input");

  await expect(placeName).toHaveValue("서울시청");
  await expect(address).toHaveValue("서울특별시 중구 세종대로 110");
  await expect(message).toHaveValue("안녕하세요! 서울시청에 도착했습니다.");

  await placeName.fill("내가 정한 장소");
  await expect(message).toHaveValue(
    "안녕하세요! 내가 정한 장소에 도착했습니다.",
  );

  await message.fill("직접 입력한 알림");
  await placeName.fill("다른 장소");
  await expect(message).toHaveValue("직접 입력한 알림");

  await page
    .getByRole("textbox", { name: "장소 검색", exact: true })
    .fill("검색어");
  await page.getByRole("button", { name: "검색" }).click();
  await page.getByRole("button", { name: /검색 결과 title/ }).click();

  // 주소는 새 위치를 따라가지만, 사용자가 입력한 이름과 메시지는 유지된다.
  await expect(address).toHaveValue("서울특별시 중구 세종대로 120");
  await expect(placeName).toHaveValue("다른 장소");
  await expect(message).toHaveValue("직접 입력한 알림");
});

test("keeps text typed before the reverse-geocode response arrives", async ({
  page,
}) => {
  await page.addInitScript(() => {
    window.ImHereBridge = {} as typeof window.ImHereBridge;
  });
  await page.route("**/api/maps/reverse-geocode**", async (route) => {
    // 응답을 늦춰 사용자가 먼저 타이핑하는 상황을 재현한다.
    await new Promise((resolve) => setTimeout(resolve, 1500));
    return route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify({
        imhereResponseCode: "SUCCESS",
        message: "ok",
        data: {
          results: [
            {
              name: "서울시청",
              region: {
                area1: { name: "서울특별시" },
                area2: { name: "중구" },
              },
              land: { name: "세종대로", number1: "110" },
            },
          ],
        },
      }),
    });
  });

  await page.goto("geofence/message");
  const placeName = page.getByRole("textbox", {
    name: "장소 이름",
    exact: true,
  });
  const address = page.getByRole("textbox", { name: "주소", exact: true });
  const message = page
    .locator("label")
    .filter({ hasText: "알림 메시지" })
    .locator("input");

  await placeName.fill("내가 먼저 입력한 장소");
  await message.fill("내가 먼저 입력한 알림");

  // 지연된 역지오코딩 응답이 도착해도 입력값은 남아 있어야 한다.
  await expect(address).toHaveValue("서울특별시 중구 세종대로 110");
  await expect(placeName).toHaveValue("내가 먼저 입력한 장소");
  await expect(message).toHaveValue("내가 먼저 입력한 알림");
});
