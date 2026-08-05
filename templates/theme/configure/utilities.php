<?php
/**
 * Asset utilities: Vite manifest reader + nav menu class filters.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! function_exists( '{prefix}_get_vite_manifest' ) ) {
	/**
	 * Read the Vite build manifest entry, static-cached per request.
	 *
	 * @param string $entry Entry name from vite.config (e.g. 'src/scripts/main.js').
	 * @return array{file: string, css: string[]}|null
	 */
	function {prefix}_get_vite_manifest( $entry = 'src/scripts/main.js' ) {
		static $manifests = array();

		if ( isset( $manifests[ $entry ] ) ) {
			return $manifests[ $entry ];
		}

		$manifest_path = get_template_directory() . '/dist/.vite/manifest.json';

		if ( ! file_exists( $manifest_path ) ) {
			$manifests[ $entry ] = null;

			return null;
		}

		// Local filesystem read of our own build artifact; wp_remote_get() is
		// for remote URLs only.
		// phpcs:ignore WordPress.WP.AlternativeFunctions.file_get_contents_file_get_contents
		$manifest = json_decode( (string) file_get_contents( $manifest_path ), true );

		if ( ! is_array( $manifest ) || ! isset( $manifest[ $entry ] ) || ! is_array( $manifest[ $entry ] ) ) {
			$manifests[ $entry ] = null;

			return null;
		}

		// The manifest is runtime data from disk - validate before trusting.
		$entry_manifest = $manifest[ $entry ];
		$file           = $entry_manifest['file'] ?? null;
		$css            = $entry_manifest['css'] ?? array();

		if ( ! is_string( $file ) || ! is_array( $css ) ) {
			$manifests[ $entry ] = null;

			return null;
		}

		$manifests[ $entry ] = array(
			'file' => $file,
			'css'  => array_values( array_filter( $css, 'is_string' ) ),
		);

		return $manifests[ $entry ];
	}
}

if ( ! function_exists( '{prefix}_add_li_class' ) ) {
	/**
	 * Add a class to every nav menu <li>.
	 *
	 * @param string[] $classes List of classes.
	 * @return string[]
	 */
	function {prefix}_add_li_class( $classes ) {
		$classes[] = 'nav__item';

		return $classes;
	}
}

if ( ! function_exists( '{prefix}_add_link_class' ) ) {
	/**
	 * Add classes to every nav menu <a>.
	 *
	 * @param string[] $attrs List of attributes.
	 * @return string[]
	 */
	function {prefix}_add_link_class( $attrs ) {
		$attrs['class'] = isset( $attrs['class'] ) ? $attrs['class'] . ' nav__link' : 'nav__link';

		return $attrs;
	}
}

add_filter( 'nav_menu_css_class', '{prefix}_add_li_class' );
add_filter( 'nav_menu_link_attributes', '{prefix}_add_link_class' );
