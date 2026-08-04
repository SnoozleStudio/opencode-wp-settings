<?php
/**
 * Header navigation walker.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

// The file name is fixed by the boot chain require in functions.php,
// so the "class-" file naming rule does not apply here.
// phpcs:disable WordPress.Files.FileName

if ( ! class_exists( '{Prefix}_Header_Nav_Walker' ) ) {
	/**
	 * Header navigation walker - default WordPress menu markup.
	 *
	 * @package {text_domain}
	 */
	class {Prefix}_Header_Nav_Walker extends Walker_Nav_Menu {}
}
