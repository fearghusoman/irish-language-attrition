import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// Base path must match the GitHub Pages repo path (https://<user>.github.io/<repo>/).
// Override at build time if the repo is renamed: VITE_BASE_PATH=/other-name/ npm run build
const BASE_PATH = process.env.VITE_BASE_PATH ?? '/irish-attrition-project/'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: process.env.NODE_ENV === 'production' ? BASE_PATH : '/',
  test: {
    environment: 'jsdom',
    setupFiles: './src/setupTests.js',
    globals: true,
  },
})
