import { defineConfig } from "vitest/config";

export const baseConfig = defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html", "lcov"],
      exclude: [
        "node_modules/**",
        "dist/**",
        "coverage/**",
        "**/*.config.ts",
        "**/*.config.js",
        "**/*.d.ts",
        "**/__mocks__/**",
        "**/test/**",
        "**/tests/**",
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80,
      },
    },
    reporters: ["verbose"],
    clearMocks: true,
    restoreMocks: true,
  },
});
