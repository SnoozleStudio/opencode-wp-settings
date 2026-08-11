<?php
/**
 * Admin-only functionality — settings page and option registration.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

/**
 * Admin settings class.
 */
class {Prefix}_Admin {
	/**
	 * Constructor — wire the admin hooks.
	 */
	public function __construct() {
		add_action( 'admin_menu', array( $this, 'register_settings_page' ) );
		add_action( 'admin_init', array( $this, 'register_settings' ) );
	}

	/**
	 * Register the settings page.
	 */
	public function register_settings_page(): void {
		add_options_page(
			__( '{plugin_name} Settings', '{text_domain}' ),
			__( '{plugin_name}', '{text_domain}' ),
			'manage_options',
			'{prefix}-settings',
			array( $this, 'render_settings_page' )
		);
	}

	/**
	 * Register the settings group, section, and example field.
	 */
	public function register_settings(): void {
		register_setting(
			'{prefix}_settings_group',
			'{prefix}_settings',
			array(
				'type'              => 'string',
				'sanitize_callback' => array( $this, 'sanitize_settings' ),
			)
		);

		add_settings_section(
			'{prefix}_settings_section',
			__( 'General', '{text_domain}' ),
			'__return_null',
			'{prefix}_settings_group'
		);

		add_settings_field(
			'{prefix}_settings_field',
			__( 'Example setting', '{text_domain}' ),
			array( $this, 'render_settings_field' ),
			'{prefix}_settings_group',
			'{prefix}_settings_section'
		);
	}

	/**
	 * Render the settings page.
	 */
	public function render_settings_page(): void {
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

	/**
	 * Render the example settings field.
	 */
	public function render_settings_field(): void {
		$value = (string) get_option( '{prefix}_settings', '' );
		?>
		<input
			type="text"
			class="regular-text"
			name="{prefix}_settings"
			value="<?php echo esc_attr( $value ); ?>"
		>
		<p class="description"><?php esc_html_e( 'An example option — replace it with your plugin settings.', '{text_domain}' ); ?></p>
		<?php
	}

	/**
	 * Sanitize the settings value.
	 *
	 * @param mixed $value The raw value.
	 * @return string
	 */
	public function sanitize_settings( $value ) {
		return sanitize_text_field( (string) $value );
	}
}
