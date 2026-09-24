import wordpress from '@wordpress/eslint-plugin';

export default [
	...wordpress.configs.recommended,
	{
		ignores: ['dist/**', 'node_modules/**', 'vendor/**'],
	},
	{
		languageOptions: {
			globals: {
				window: 'readonly',
				document: 'readonly',
				navigator: 'readonly',
				requestAnimationFrame: 'readonly',
				cancelAnimationFrame: 'readonly',
				performance: 'readonly',
				IntersectionObserver: 'readonly',
				ResizeObserver: 'readonly',
				getComputedStyle: 'readonly',
				console: 'readonly',
			},
		},
	},
	{
		rules: {
			'no-console': ['error', { allow: ['warn', 'error'] }],
		},
	},
];