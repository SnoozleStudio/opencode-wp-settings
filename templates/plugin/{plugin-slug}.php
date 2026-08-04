<?php
/**
 * Plugin Name:       {plugin_name}
 * Plugin URI:        https://example.com/{plugin_slug}
 * Description:       Enterprise-grade WordPress plugin. {description}
 * Version:           1.0.0
 * Requires at least: 6.8
 * Requires PHP:      8.2
 * Author:            Snoozle Studio
 * Author URI:        https://snoozle.studio
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       {text_domain}
 * Domain Path:       /languages
 *
 * @package {text_domain}
 */
if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

define( '{PREFIX}_VERSION', '1.0.0' );
define( '{PREFIX}_FILE', __FILE__ );
define( '{PREFIX}_DIR', plugin_dir_path( __FILE__ ) );
define( '{PREFIX}_URL', plugin_dir_url( __FILE__ ) );

require_once {PREFIX}_DIR . 'includes/class-{prefix}-plugin.php';

/**
 * Boot the plugin singleton.
 *
 * @return {Prefix}_Plugin
 */
function {prefix}_plugin() {
	return {Prefix}_Plugin::get_instance();
}

{prefix}_plugin();
