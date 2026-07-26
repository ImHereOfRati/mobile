import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const webRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const sourceRoot = path.join(webRoot, "src");
const allowedColorFile = path.join(sourceRoot, "design-system", "tokens.css");
const colorLiteralPattern =
  /#[\da-f]{3,8}\b|(?:rgb|hsl)a?\(\s*[\d.]+(?:\s*[,/]\s*|\s+)[\d.]+/gi;

async function collectFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await collectFiles(entryPath)));
      continue;
    }

    if (/\.(css|ts|tsx)$/.test(entry.name) && !entry.name.includes(".test.")) {
      files.push(entryPath);
    }
  }

  return files;
}

const violations = [];
for (const filePath of await collectFiles(sourceRoot)) {
  if (filePath === allowedColorFile) continue;

  const source = await readFile(filePath, "utf8");
  const matches = source.match(colorLiteralPattern);
  if (matches !== null) {
    violations.push(
      `${path.relative(webRoot, filePath)}: ${[...new Set(matches)].join(", ")}`,
    );
  }
}

if (violations.length > 0) {
  throw new Error(
    `Use design tokens instead of color literals:\n${violations.join("\n")}`,
  );
}

console.log("Color token check passed.");
