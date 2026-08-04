<?php
/**
 * Main plugin class - singleton with load-order-safe hook wiring.
 *
 * @package {text_domain}
 */
if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

/**
 * Core plugin class.
 */
class {Prefix}_Plugin {
	/**
	 * Singleton instance.
	 *
	 * @var {Prefix}_Plugin|null
	 */
	private static $instance = null;

	/**
	 * Get the singleton instance.
	 *
	 * @return {Prefix}_Plugin
	 */
	public static function get_instance() {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}

		return self::$instance;
	}

	/**
	 * Private constructor - wire hooks.
	 */
	private function __construct() {
		add_action( 'plugins_loaded', array( $this, 'load_textdomain' ) );
		add_action( 'init', array( $this, 'register_post_types' ) );
		add_action( 'rest_api_init', array( $this, 'register_rest_routes' ) );
	}

	/**
	 * Load plugin textdomain.
	 */
	public function load_textdomain() {
		load_plugin_textdomain( '{text_domain}', false, dirname( plugin_basename( {PREFIX}_FILE ) ) . '/languages' );
	}

	/**
	 * Register post types.
	 */
	public function register_post_types() {
		register_post_type(
			'{prefix}_item',
			array(
				'labels'       => array(
					'name'          => __( 'Items', '{text_domain}' ),
					'singular_name' => __( 'Item', '{text_domain}' ),
				),
				'public'       => true,
				'show_in_rest' => true,
				'menu_icon'    => 'dashicons-admin-generic',
				'supports'     => array( 'title', 'editor', 'thumbnail' ),
			)
		);
	}

	/**
	 * Register REST routes.
	 */
	public function register_rest_routes() {
		register_rest_route(
			'{prefix}/v1',
			'/items/(?P<id>[\d]+)',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $this, 'rest_get_item' ),
				'permission_callback' => array( $this, 'rest_permission_check' ),
				'args'                => array(
					'id' => array(
						'validate_callback' => static function ( $value ) {
							return is_numeric( $value );
						},
						'sanitize_callback' => 'absint',
					),
				),
			)
		);
	}

	/**
	 * REST permission callback.
	 *
	 * @return bool
	 */
	public function rest_permission_check() {
		return current_user_can( 'edit_posts' );
	}

	/**
	 * REST item handler.
	 *
	 * @param  WP_REST_Request  $request  The request.
	 * @return WP_REST_Response|WP_Error
	 */
	public function rest_get_item( $request ) {
		$item = get_post( (int) $request['id'] );

		if ( ! $item || '{prefix}_item' !== $item->post_type ) {
			return new WP_Error( 'rest_item_not_found', __( 'Item not found.', '{text_domain}' ), array( 'status' => 404 ) );
		}

		return rest_ensure_response(
			array(
				'id'    => $item->ID,
				'title' => get_the_title( $item ),
			)
		);
	}
}
