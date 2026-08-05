<?php
/**
 * Script and style enqueues - Vite manifest-driven.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! function_exists( '{prefix}_enqueue_assets' ) ) {
	/**
	 * Enqueue the Vite-built entry script and its CSS.
	 */
	function {prefix}_enqueue_assets(): void {
		$manifest = {prefix}_get_vite_manifest();

		if ( null === $manifest ) {
			return;
		}

		$dist_url = get_template_directory_uri() . '/dist';

		foreach ( $manifest['css'] as $css ) {
			// Hashed filenames are the cache-buster; a version param is
			// redundant, so the MissingVersion sniff is disabled here.
			// phpcs:disable WordPress.WP.EnqueuedResourceParameters.MissingVersion
			wp_enqueue_style(
				'{prefix}-' . sanitize_title( $css ),
				$dist_url . '/' . $css,
				array(),
				null
			);
			// phpcs:enable WordPress.WP.EnqueuedResourceParameters.MissingVersion
		}

		$js = $manifest['file'];

		// Hashed filenames are the cache-buster; a version param is
		// redundant, so the MissingVersion sniff is disabled here.
		// phpcs:disable WordPress.WP.EnqueuedResourceParameters.MissingVersion
		wp_enqueue_script(
			'{prefix}-main',
			$dist_url . '/' . $js,
			array(),
			null,
			array(
				'in_footer' => true,
				'strategy'  => 'defer',
			)
		);
		// phpcs:enable WordPress.WP.EnqueuedResourceParameters.MissingVersion
	}
}
add_action( 'wp_enqueue_scripts', '{prefix}_enqueue_assets' );

if ( ! function_exists( '{prefix}_script_module_type' ) ) {
	/**
	 * Rewrite the main script tag to type="module" (Vite ES module output).
	 *
	 * @param string $tag The script tag.
	 * @param string $handle The script handle.
	 * @return string
	 */
	function {prefix}_script_module_type( $tag, $handle ) {
		if ( '{prefix}-main' !== $handle ) {
			return $tag;
		}

		return str_replace( "type='text/javascript'", 'type="module"', $tag );
	}
}
add_filter( 'script_loader_tag', '{prefix}_script_module_type', 10, 2 );
