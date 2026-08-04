<?php
/**
 * ACF Pro integration: acf-json sync paths + theme constants.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! defined( '{PREFIX}_THEME_DIR_PATH' ) ) {
	define( '{PREFIX}_THEME_DIR_PATH', get_template_directory() );
}

if ( ! defined( '{PREFIX}_THEME_DIR_URL' ) ) {
	define( '{PREFIX}_THEME_DIR_URL', get_template_directory_uri() );
}

if ( ! function_exists( '{prefix}_acf_json_save_point' ) ) {
	/**
	 * Save ACF field groups to acf-json/ for version control.
	 *
	 * @param string $path Save path (filter contract; unused).
	 * @return string
	 */
	function {prefix}_acf_json_save_point( $path ) { // phpcs:ignore Generic.CodeAnalysis.UnusedFunctionParameter.Found
		return {PREFIX}_THEME_DIR_PATH . '/acf-json';
	}
}
add_filter( 'acf/settings/save_json', '{prefix}_acf_json_save_point' );

if ( ! function_exists( '{prefix}_acf_json_load_point' ) ) {
	/**
	 * Load ACF field groups from acf-json/.
	 *
	 * @param string[] $paths Load paths.
	 * @return string[]
	 */
	function {prefix}_acf_json_load_point( $paths ) {
		$paths[] = {PREFIX}_THEME_DIR_PATH . '/acf-json';

		return $paths;
	}
}
add_filter( 'acf/settings/load_json', '{prefix}_acf_json_load_point' );
