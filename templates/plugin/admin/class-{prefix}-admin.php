<?php
/**
 * Admin-only functionality - still capability-checked inside.
 *
 * @package {text_domain}
 */
if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

if ( ! function_exists( '{prefix}_admin_settings_page' ) ) {
	/**
	 * Register the settings page.
	 */
	function {prefix}_admin_settings_page() {
		add_options_page(
			__( '{plugin_name} Settings', '{text_domain}' ),
			__( '{plugin_name}', '{text_domain}' ),
			'manage_options',
			'{prefix}-settings',
			'{prefix}_admin_render_settings'
		);
	}
}
add_action( 'admin_menu', '{prefix}_admin_settings_page' );

if ( ! function_exists( '{prefix}_admin_render_settings' ) ) {
	/**
	 * Render the settings page.
	 */
	function {prefix}_admin_render_settings() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have permission to access this page.', '{text_domain}' ) );
		}
		?>
		<div class="wrap">
			<h1><?php esc_html_e( '{plugin_name} Settings', '{text_domain}' ); ?></h1>
			<form method="post" action="options.php">
				<?php
				settings_fields( '{prefix}_settings_group' );
				do_settings_sections( '{prefix}_settings_group' );
				submit_button();
				?>
			</form>
		</div>
		<?php
	}
}
