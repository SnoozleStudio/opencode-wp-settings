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