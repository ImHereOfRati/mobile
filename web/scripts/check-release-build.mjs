import { readFile } from "node:fs/promises";
import path from "node:path";

const releaseSha = process.env.RELEASE_SHA?.trim();
if (!releaseSha || !/^[0-9a-f]{40}$/.test(releaseSha)) {
  throw new Error("RELEASE_SHA must be a lowercase 40-character commit SHA.");
}

const releasePrefix = `/app/releases/${releaseSha}/`;
const html = await readFile("dist/app/index.html", "utf8");
const assetPaths = [
  ...html.matchAll(/(?:src|href)="([^"]+\.(?:css|js))"/g),
].map((match) => match[1]);

if (assetPaths.length === 0) {
  throw new Error("Immutable release build has no direct assets.");
}
for (const assetPath of assetPaths) {
  if (!assetPath.startsWith(releasePrefix)) {
    throw new Error(
      `Immutable release asset does not use ${releasePrefix}: ${assetPath}`,
    );
  }
}

const entryScript = assetPaths.find((assetPath) => assetPath.endsWith(".js"));
if (!entryScript) {
  throw new Error("Immutable release build has no JavaScript entry.");
}
const entrySource = await readFile(
  path.join("dist", "app", entryScript.slice(releasePrefix.length)),
  "utf8",
);
if (!entrySource.includes(releasePrefix)) {
  throw new Error(
    "React Router basename does not contain the immutable release prefix.",
  );
}

console.log(
  `Immutable release build uses ${releasePrefix} for ${assetPaths.length} assets.`,
);
