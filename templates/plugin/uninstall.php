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

if ( ! function_exists( '{prefix}_uninstall_site_data' ) ) {
	/**
	 * Remove this plugin's data from the current site.
	 */
	function {prefix}_uninstall_site_data(): void {
		$options = array(
			'{prefix}_version',
			'{prefix}_settings',
		);

		foreach ( $options as $option ) {
			delete_option( $option );
		}

		$items = get_posts(
			array(
				'post_type'   => '{prefix}_item',
				'post_status' => 'any',
				'numberposts' => -1,
				'fields'      => 'ids',
			)
		);

		foreach ( $items as $item_id ) {
			wp_delete_post( (int) $item_id, true );
		}
	}
}

if ( is_multisite() ) {
	$sites = get_sites(
		array(
			'fields' => 'ids',
			'number' => 0,
		)
	);

	foreach ( $sites as $site_id ) {
		switch_to_blog( (int) $site_id );
		{prefix}_uninstall_site_data();
		restore_current_blog();
	}
} else {
	{prefix}_uninstall_site_data();
}
