<?php
/**
 * Static page template.
 *
 * @package {text_domain}
 */
if ( ! defined( 'ABSPATH' ) ) {
	exit();
}

get_header();
?>

<?php
while ( have_posts() ) {
	the_post();
	?>
	<article <?php post_class( 'page' ); ?>>
		<header class="page__header">
			<h1 class="page__title"><?php the_title(); ?></h1>
		</header>

		<div class="page__content">
			<?php the_content(); ?>
		</div>
	</article>
	<?php
}
?>

<?php
get_footer();
