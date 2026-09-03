import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import { JSDOM } from "jsdom";
import { build } from "vite";

const webRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const landingConfigFile = path.join(webRoot, "vite.landing.config.ts");
const entryFile = path.join(webRoot, "src", "landing", "prerender-entry.tsx");
const indexHtmlFile = path.join(webRoot, "dist", "landing", "index.html");
const rootDivMarker = '<div id="landing-root"></div>';

async function bundlePrerenderEntry() {
  const result = await build({
    configFile: landingConfigFile,
    logLevel: "warn",
    build: {
      ssr: entryFile,
      write: false,
      outDir: "dist/landing-ssr-tmp",
    },
  });

  const output = Array.isArray(result) ? result[0] : result;
  const chunk = output.output.find((item) => item.type === "chunk");

  if (!chunk) {
    throw new Error("Prerender entry bundle did not produce a JS chunk.");
  }

  return chunk.code;
}

async function renderLandingMarkup(bundleCode) {
  const dom = new JSDOM("<!doctype html><html><body></body></html>", {
    url: "https://imhere.ratiko.co.kr/",
  });

  for (const key of ["window", "document", "navigator", "location"]) {
    if (!(key in globalThis)) {
      globalThis[key] = dom.window[key];
    }
  }

  // Written under web/node_modules so Node's module resolution can find
  // react/react-dom the same way the rest of the workspace does.
  const tempDir = path.join(webRoot, "node_modules", ".landing-ssr-tmp");
  const tempFile = path.join(tempDir, "prerender-entry.mjs");
  await mkdir(tempDir, { recursive: true });

  try {
    await writeFile(tempFile, bundleCode, "utf8");
    const { renderLandingMarkup } = await import(pathToFileURL(tempFile).href);
    return renderLandingMarkup();
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }
}

function assertMarkupLooksComplete(markup) {
  const requiredSnippets = [
    'id="product-title"',
    "ImHere는 어떤 서비스인가요?",
  ];

  for (const snippet of requiredSnippets) {
    if (!markup.includes(snippet)) {
      throw new Error(
        `Prerendered landing markup is missing expected content: ${snippet}`,
      );
    }
  }
}

async function injectMarkupIntoBuiltHtml(markup) {
  const html = await readFile(indexHtmlFile, "utf8");

  if (!html.includes(rootDivMarker)) {
    throw new Error(
      `Could not find "${rootDivMarker}" in ${indexHtmlFile} to inject prerendered markup.`,
    );
  }

  const nextHtml = html.replace(
    rootDivMarker,
    `<div id="landing-root">${markup}</div>`,
  );

  await writeFile(indexHtmlFile, nextHtml, "utf8");
}

const bundleCode = await bundlePrerenderEntry();
const markup = await renderLandingMarkup(bundleCode);
assertMarkupLooksComplete(markup);
await injectMarkupIntoBuiltHtml(markup);

console.log(
  "Prerendered landing markup injected into dist/landing/index.html.",
);
