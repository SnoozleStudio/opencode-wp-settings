<?php
/**
 * Theme setup: menus, theme supports, text domain, cleanup.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! function_exists( '{prefix}_theme_setup' ) ) {
	/**
	 * Register theme supports and menus.
	 */
	function {prefix}_theme_setup(): void {
		load_theme_textdomain( '{text_domain}', get_template_directory() . '/languages' );

		add_theme_support( 'title-tag' );
		add_theme_support( 'post-thumbnails' );
		add_theme_support( 'custom-logo' );
		add_theme_support(
			'html5',
			array(
				'search-form',
				'gallery',
				'caption',
				'style',
				'script',
				'navigation-widgets',
			)
		);

		register_nav_menus(
			array(
				'header' => esc_html__( 'Header Menu', '{text_domain}' ),
				'footer' => esc_html__( 'Footer Menu', '{text_domain}' ),
			)
		);
	}
}
add_action( 'after_setup_theme', '{prefix}_theme_setup' );

if ( ! function_exists( '{prefix}_cleanup' ) ) {
	/**
	 * Remove front-end bloat: emoji, embed, global styles, unused image sizes.
	 */
	function {prefix}_cleanup(): void {
		remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
		remove_action( 'wp_print_styles', 'print_emoji_styles' );
		remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
		remove_action( 'wp_head', 'wp_oembed_add_host_js' );
		remove_action( 'wp_enqueue_scripts', 'wp_enqueue_global_styles' );
		remove_action( 'wp_body_open', 'wp_global_styles_render_svg_filters' );
	}
}
add_action( 'init', '{prefix}_cleanup' );

if ( ! function_exists( '{prefix}_content_width' ) ) {
	/**
	 * Set the content width (classic themes only).
	 */
	function {prefix}_content_width(): void {
		$GLOBALS['content_width'] = apply_filters( '{prefix}_content_width', 1200 );
	}
}
add_action( 'after_setup_theme', '{prefix}_content_width', 0 );
