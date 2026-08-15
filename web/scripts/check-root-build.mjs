import { readFile } from "node:fs/promises";

const html = await readFile("dist/app/index.html", "utf8");
const assetPaths = [
  ...html.matchAll(/(?:src|href)="([^"]+\.(?:css|js))"/g),
].map((match) => match[1]);

if (assetPaths.length === 0) {
  throw new Error("App root build has no direct assets.");
}

for (const assetPath of assetPaths) {
  if (!assetPath.startsWith("/app/")) {
    throw new Error(`App root asset does not use /app/: ${assetPath}`);
  }
}

console.log(`App root build uses /app/ for ${assetPaths.length} assets.`);
