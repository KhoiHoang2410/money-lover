/// <reference types="vitest/config" />
import { defineConfig } from "vite";
import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import yaml from "@modyfi/vite-plugin-yaml";

// Vite + React SPA (ADR-0018). YAML plugin lets i18n author locale resources as
// YAML (PRD i18n). Tailwind v4 plugin wires the lime-dark theme (ADR-0019).
export default defineConfig({
  plugins: [react(), tailwindcss(), yaml()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./vitest.setup.ts"],
    css: false,
  },
});
