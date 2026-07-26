import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import subsetFont from "subset-font";

const webRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const repositoryRoot = path.resolve(webRoot, "..");
const sourceRoot = path.join(webRoot, "src");
const outputRoot = path.join(sourceRoot, "assets", "fonts");

const fonts = [
  {
    input: path.join(
      repositoryRoot,
      "assets",
      "fonts",
      "GmarketSansTTFMedium.ttf",
    ),
    output: path.join(outputRoot, "gmarket-sans-medium.woff2"),
  },
  {
    input: path.join(
      repositoryRoot,
      "assets",
      "fonts",
      "GmarketSansTTFBold.ttf",
    ),
    output: path.join(outputRoot, "gmarket-sans-bold.woff2"),
  },
];

async function collectText(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const contents = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      contents.push(await collectText(entryPath));
      continue;
    }

    if (/\.(html|json|ts|tsx)$/.test(entry.name)) {
      contents.push(await readFile(entryPath, "utf8"));
    }
  }

  return contents.join("\n");
}

const ascii =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" +
  " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~";
const glyphs = [...new Set(`${ascii}${await collectText(sourceRoot)}`)].join(
  "",
);

await mkdir(outputRoot, { recursive: true });

for (const font of fonts) {
  const source = await readFile(font.input);
  const subset = await subsetFont(source, glyphs, { targetFormat: "woff2" });
  await writeFile(font.output, subset);
  console.log(
    `${path.relative(repositoryRoot, font.output)}: ${subset.byteLength} bytes`,
  );
}
