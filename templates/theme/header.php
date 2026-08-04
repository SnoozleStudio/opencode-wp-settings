<?php
/**
 * Header template.
 *
 * @package {text_domain}
 */
if ( ! defined( 'ABSPATH' ) ) {
	exit();
}
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="profile" href="https://gmpg.org/xfn/11">
	<?php wp_head(); ?>
</head>

<body <?php body_class(); ?>>
<?php wp_body_open(); ?>

<a class="skip-link screen-reader-text" href="#main">
	<?php esc_html_e( 'Skip to content', '{text_domain}' ); ?>
</a>

<header class="site-header">
	<nav class="site-nav" aria-label="<?php esc_attr_e( 'Primary', '{text_domain}' ); ?>">
		<?php
		wp_nav_menu(
			array(
				'theme_location' => 'header',
				'container'      => false,
				'menu_class'     => 'site-nav__list',
				'fallback_cb'    => false,
			)
		);
		?>
	</nav>
</header>

<main id="main" class="site-main">
