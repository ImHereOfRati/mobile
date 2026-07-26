import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const appRoot = path.join(webRoot, "dist", "app");
const landingRoot = path.join(webRoot, "dist", "landing");

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(entryPath)));
    } else {
      files.push(entryPath);
    }
  }

  return files;
}

async function readManifest(root) {
  return JSON.parse(
    await readFile(path.join(root, ".vite", "manifest.json"), "utf8"),
  );
}

const [appManifest, landingManifest, appFiles, landingFiles] =
  await Promise.all([
    readManifest(appRoot),
    readManifest(landingRoot),
    collectFiles(appRoot),
    collectFiles(landingRoot),
  ]);

const appGraph = JSON.stringify(appManifest).toLowerCase();
if (appGraph.includes("landing") || appGraph.includes("three")) {
  throw new Error(
    "The app build manifest references landing or Three.js code.",
  );
}

const appSource = (
  await Promise.all(
    appFiles
      .filter((file) => /\.(html|js|css|json)$/.test(file))
      .map((file) => readFile(file, "utf8")),
  )
).join("\n");

for (const marker of ["철수에게 귀가 알림", "threejourney", "webglrenderer"]) {
  if (appSource.toLowerCase().includes(marker.toLowerCase())) {
    throw new Error(`The app build contains a landing marker: ${marker}`);
  }
}

const appHtml = await readFile(path.join(appRoot, "index.html"), "utf8");
if (!appHtml.includes("/app/assets/")) {
  throw new Error("The app build is not rooted at /app/.");
}

const landingHtml = await readFile(
  path.join(landingRoot, "index.html"),
  "utf8",
);
if (!landingHtml.includes("/assets/")) {
  throw new Error("The landing build is not rooted at the domain root.");
}

const landingSource = (
  await Promise.all(
    landingFiles
      .filter((file) => /\.(html|js|css|json)$/.test(file))
      .map((file) => readFile(file, "utf8")),
  )
).join("\n");
if (
  landingManifest["index.html"]?.isEntry !== true ||
  !landingSource.toLowerCase().includes("webgl")
) {
  throw new Error("The landing build does not contain its 3D journey.");
}

console.log("Landing and app build isolation check passed.");
