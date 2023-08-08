import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import * as path from "path";
import { contracts } from "../contracts/resolver";

export default defineConfig({
  plugins: [react(), contracts()],
  assetsInclude: ["favicon.ico"],
  server: {
    port: 3000,
    fs: {
      strict: false,
    },
  },
  resolve: {
    alias: [{ find: "@", replacement: path.resolve(__dirname, "./src") }],
  },
  build: {
    target: "es2022",
    minify: true,
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          antd: ["antd"],
          latticexyz: [
            "@latticexyz/utils",
            "@latticexyz/react",
            "@latticexyz/dev-tools",
            "@latticexyz/recs",
          ],
        },
      },
    },
  },
  optimizeDeps: {
    exclude: ["src/lib/snarkjs.min.js"],
  },
});
