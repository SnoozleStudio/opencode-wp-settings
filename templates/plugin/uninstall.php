<?php
/**
 * Uninstall handler - permanent data removal ONLY.
 * Deactivation is handled by the deactivation hook; this file is for
 * options, transients, and tables the plugin owns.
 *
 * @package {text_domain}
 */

if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) {
	exit();
}

$options = array(
	'{prefix}_version',
	'{prefix}_settings',
);

foreach ( $options as $option ) {
	delete_option( $option );
}

// Multisite: delete site options here when the plugin is uninstalled
// network-wide.
