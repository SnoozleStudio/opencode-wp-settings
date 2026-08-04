<?php
/**
 * Front page template - sections driven by ACF fields.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

get_header();

$hero = get_field( 'hero' );
?>

<section class="hero" id="hero">
	<?php if ( is_array( $hero ) && ! empty( $hero['title'] ) ) { ?>
		<h1 class="hero__title"><?php echo esc_html( $hero['title'] ); ?></h1>
	<?php } else { ?>
		<h1 class="hero__title"><?php bloginfo( 'name' ); ?></h1>
	<?php } ?>

	<?php if ( is_array( $hero ) && ! empty( $hero['content'] ) ) { ?>
		<div class="hero__content"><?php echo wp_kses_post( $hero['content'] ); ?></div>
	<?php } ?>
</section>

<?php
get_footer();
