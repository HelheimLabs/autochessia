import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { contracts } from '../contracts/resolver'

export default defineConfig({
  plugins: [react(), contracts()],
  server: {
    port: 3000,
    fs: {
      strict: false,
    },
  },
  build: {
    target: "es2022",
    minify: true,
    sourcemap: true,
  },
  
});
