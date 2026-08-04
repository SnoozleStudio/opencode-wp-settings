<?php
/**
 * Fallback template - the theme must never be blank.
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
	<article <?php post_class( 'post' ); ?>>
		<h2 class="post__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
		<div class="post__content">
			<?php the_excerpt(); ?>
		</div>
	</article>
	<?php
}
?>

<?php
get_footer();
