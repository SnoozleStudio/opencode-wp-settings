<?php
/**
 * Front-end functionality - enqueues, shortcodes, public hooks.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! function_exists( '{prefix}_enqueue_assets' ) ) {
	/**
	 * Enqueue front-end assets.
	 */
	function {prefix}_enqueue_assets(): void {
		wp_enqueue_style(
			'{prefix}-public',
			{PREFIX}_URL . 'public/css/public.css',
			array(),
			{PREFIX}_VERSION
		);

		wp_enqueue_script(
			'{prefix}-public',
			{PREFIX}_URL . 'public/js/public.js',
			array(),
			{PREFIX}_VERSION,
			array(
				'in_footer' => true,
				'strategy'  => 'defer',
			)
		);
	}
}
add_action( 'wp_enqueue_scripts', '{prefix}_enqueue_assets' );
