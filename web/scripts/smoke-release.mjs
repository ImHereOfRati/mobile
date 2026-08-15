import { pathToFileURL } from "node:url";

const immutableCache = /(?:^|,)\s*(?:public,\s*)?max-age=31536000(?:,|$)/i;

export async function smokeRelease({
  releaseUrl,
  expectedSha,
  fetchImpl = fetch,
}) {
  const release = new URL(releaseUrl);
  const expectedDirectory = `/app/releases/${expectedSha}/`;
  const expectedPath = `${expectedDirectory}index.html`;
  if (release.pathname !== expectedPath) {
    throw new Error(`Release URL must end with ${expectedPath}`);
  }

  const htmlResponse = await fetchImpl(release);
  await assertResponse(htmlResponse, "release index");
  assertImmutable(htmlResponse, "release index");

  const html = await htmlResponse.text();
  if (!html.includes('id="root"')) {
    throw new Error("Release index does not contain the React root.");
  }

  const assetPaths = [
    ...html.matchAll(/(?:src|href)="([^"]+\.(?:css|js))"/g),
  ].map((match) => match[1]);
  if (!assetPaths.some((asset) => asset.endsWith(".js"))) {
    throw new Error("Release index does not reference a JavaScript asset.");
  }

  const assetUrls = [...new Set(assetPaths)].map(
    (asset) => new URL(asset, release),
  );
  for (const assetUrl of assetUrls) {
    if (!assetUrl.pathname.startsWith(expectedDirectory)) {
      throw new Error(
        `Asset escaped the immutable release prefix: ${assetUrl.pathname}`,
      );
    }
    const response = await fetchImpl(assetUrl);
    await assertResponse(response, `asset ${assetUrl.pathname}`);
    assertImmutable(response, `asset ${assetUrl.pathname}`);
  }

  return { assetCount: assetUrls.length, releaseUrl: release.href };
}

async function assertResponse(response, label) {
  if (response.ok) return;
  const body = await response.text();
  throw new Error(
    `${label} returned ${response.status}: ${body.slice(0, 200)}`,
  );
}

function assertImmutable(response, label) {
  const cacheControl = response.headers.get("cache-control") ?? "";
  if (
    !cacheControl.toLowerCase().includes("immutable") ||
    !immutableCache.test(cacheControl)
  ) {
    throw new Error(`${label} is not cached as immutable: ${cacheControl}`);
  }
}

if (
  process.argv[1] &&
  pathToFileURL(process.argv[1]).href === import.meta.url
) {
  const releaseUrl = process.env.RELEASE_URL?.trim();
  const expectedSha = process.env.RELEASE_SHA?.trim();
  if (!releaseUrl || !expectedSha) {
    throw new Error("RELEASE_URL and RELEASE_SHA are required.");
  }

  const result = await smokeRelease({ releaseUrl, expectedSha });
  console.log(
    `Release smoke passed: ${result.releaseUrl} (${result.assetCount} assets)`,
  );
}
