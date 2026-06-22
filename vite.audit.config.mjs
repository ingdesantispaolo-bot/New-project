import { defineConfig } from "vite";

export default defineConfig({
  build: {
    target: "node22",
    ssr: "scripts/audit-mission-generation.ts",
    outDir: "dist-audit",
    emptyOutDir: true,
  },
});
