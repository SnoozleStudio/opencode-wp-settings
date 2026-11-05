<?php
/**
 * {theme_name} functions and definitions.
 *
 * Boot loader only - the boot chain is load-order-sensitive:
 * utilities, configure, js-css, acf.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

require get_template_directory() . '/configure/utilities.php';
require get_template_directory() . '/configure/configure.php';
require get_template_directory() . '/configure/js-css.php';
require get_template_directory() . '/configure/acf.php';
