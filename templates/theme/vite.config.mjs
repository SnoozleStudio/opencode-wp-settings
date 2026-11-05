import tailwindcss from '@tailwindcss/vite';
import { resolve } from 'node:path';
import { defineConfig } from 'vite';

// WordPress theme build.
// - base defaults to the absolute theme URL; set VITE_BASE at build time for
//   subdirectory installs (e.g. /blog/wp-content/themes/{theme_slug}/dist/)
// - rolldownOptions.input names the JS entry (no index.html exists in a theme)
// - manifest.json is consumed by configure/js-css.php for enqueueing
const JS_FILE = resolve('src/scripts/main.js');
const BASE = process.env.VITE_BASE || '/wp-content/themes/{theme_slug}/dist/';

export default defineConfig({
	base: BASE,
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
