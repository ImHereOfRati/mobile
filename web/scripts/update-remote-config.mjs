import { pathToFileURL } from "node:url";

const remoteConfigOrigin = "https://firebaseremoteconfig.googleapis.com";

export async function updateRemoteConfig({
  projectId,
  releaseUrl,
  accessToken,
  fetchImpl = fetch,
}) {
  const endpoint = `${remoteConfigOrigin}/v1/projects/${encodeURIComponent(projectId)}/remoteConfig`;
  const authorization = `Bearer ${accessToken}`;
  const currentResponse = await fetchImpl(endpoint, {
    headers: { Authorization: authorization },
  });
  await assertResponse(currentResponse, "Remote Config download");

  const etag = currentResponse.headers.get("etag");
  if (!etag) throw new Error("Remote Config download did not return an ETag.");

  const template = await currentResponse.json();
  delete template.version;
  template.parameters ??= {};
  template.parameters.web_app_url = {
    ...template.parameters.web_app_url,
    defaultValue: { value: releaseUrl },
    description:
      "Immutable React app release selected by deployment automation.",
  };

  const body = JSON.stringify(template);
  await publishTemplate({
    accessToken,
    body,
    endpoint: `${endpoint}?validate_only=true`,
    etag,
    fetchImpl,
    label: "Remote Config validation",
  });
  const publishedResponse = await publishTemplate({
    accessToken,
    body,
    endpoint,
    etag,
    fetchImpl,
    label: "Remote Config publish",
  });

  return {
    etag: publishedResponse.headers.get("etag"),
    releaseUrl,
  };
}

async function publishTemplate({
  accessToken,
  body,
  endpoint,
  etag,
  fetchImpl,
  label,
}) {
  const response = await fetchImpl(endpoint, {
    body,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json; UTF-8",
      "If-Match": etag,
    },
    method: "PUT",
  });
  await assertResponse(response, label);
  return response;
}

async function assertResponse(response, label) {
  if (response.ok) return;
  const body = await response.text();
  throw new Error(
    `${label} returned ${response.status}: ${body.slice(0, 500)}`,
  );
}

if (
  process.argv[1] &&
  pathToFileURL(process.argv[1]).href === import.meta.url
) {
  const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
  const releaseUrl = process.env.RELEASE_URL?.trim();
  const accessToken = process.env.GOOGLE_ACCESS_TOKEN?.trim();
  if (!projectId || !releaseUrl || !accessToken) {
    throw new Error(
      "FIREBASE_PROJECT_ID, RELEASE_URL, and GOOGLE_ACCESS_TOKEN are required.",
    );
  }

  const result = await updateRemoteConfig({
    accessToken,
    projectId,
    releaseUrl,
  });
  console.log(
    `Remote Config web_app_url published: ${result.releaseUrl} (${result.etag ?? "no ETag"})`,
  );
}
