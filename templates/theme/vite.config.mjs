import tailwindcss from '@tailwindcss/vite';
import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// WordPress theme build.
// - base MUST stay the absolute theme URL or font/asset URLs break in production
// - rolldownOptions.input names the JS entry (no index.html exists in a theme)
// - manifest.json is consumed by configure/js-css.php for enqueueing
const JS_FILE = resolve('src/scripts/main.js');

export default defineConfig({
  base: '/wp-content/themes/{theme_slug}/dist/',
  plugins: [tailwindcss()],
  build: {
    assetsDir: '',
    manifest: true,
    outDir: 'dist',
    emptyOutDir: true,
    chunkSizeWarningLimit: 600,
    rolldownOptions: {
      input: JS_FILE,
      output: {
        codeSplitting: {
          groups: [
            {
              name: 'vendor',
              test: /node_modules/,
              maxSize: 300000,
            },
          ],
        },
      },
    },
  },
});
