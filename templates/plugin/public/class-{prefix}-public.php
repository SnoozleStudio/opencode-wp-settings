<?php
/**
 * Front-end functionality — enqueues, shortcodes, public hooks.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

/**
 * Front-end assets class.
 */
class {Prefix}_Public {
	/**
	 * Constructor — wire the public hooks.
	 */
	public function __construct() {
		add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_assets' ) );
	}

	/**
	 * Enqueue front-end assets.
	 */
	public function enqueue_assets(): void {
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
