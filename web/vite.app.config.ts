import { fileURLToPath, URL } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

const appBasePath = process.env.VITE_APP_BASE_PATH?.trim() || "/app/";
if (appBasePath !== "/app/") {
  throw new Error("VITE_APP_BASE_PATH must be /app/.");
}
const sourceRoot = fileURLToPath(new URL("./src", import.meta.url));

export default defineConfig({
  root: "app",
  base: appBasePath,
  cacheDir: "../node_modules/.vite-app",
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
