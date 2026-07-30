import { defineConfig } from "vite";
import { godotWebCompression } from "./scripts/vite-godot-compression.mjs";

export default defineConfig({
  base: "./",
  plugins: [godotWebCompression()],
  optimizeDeps: {
    entries: ["index.html"],
  },
  server: {
    host: "127.0.0.1",
    port: 5173,
    watch: {
      ignored: [
        "**/.tmp/**",
        "**/.tmp-godot/**",
        "**/artifacts/**",
        "**/dist/**",
        "**/godot/.godot/**",
      ],
    },
  },
});
