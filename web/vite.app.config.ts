import { fileURLToPath, URL } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const appBasePath = process.env.VITE_APP_BASE_PATH?.trim() || "/app/";
if (!/^\/app\/(?:releases\/[0-9a-f]{40}\/)?$/.test(appBasePath)) {
  throw new Error(
    "VITE_APP_BASE_PATH must be /app/ or /app/releases/<40-character SHA>/.",
  );
}
const sourceRoot = fileURLToPath(new URL("./src", import.meta.url));

export default defineConfig({
  root: "app",
  base: appBasePath,
  plugins: [react()],
  resolve: {
    alias: [
      { find: "@", replacement: sourceRoot },
      { find: `${appBasePath}src`, replacement: sourceRoot },
      { find: "/src", replacement: sourceRoot },
    ],
  },
  build: {
    outDir: "../dist/app",
    emptyOutDir: true,
    manifest: true,
  },
});
