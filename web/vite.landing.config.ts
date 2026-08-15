import { fileURLToPath, URL } from "node:url";

import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  root: "landing",
  base: "/",
  cacheDir: "../node_modules/.vite-landing",
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
      "/src": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  build: {
    outDir: "../dist/landing",
    emptyOutDir: true,
    manifest: true,
  },
});
