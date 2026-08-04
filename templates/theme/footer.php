<?php
/**
 * Footer template.
 *
 * @package {text_domain}
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit();
}
?>
</main>

<footer class="site-footer">
	<p>
		&copy; <?php echo esc_html( date_i18n( 'Y' ) ); ?>
		<a href="<?php echo esc_url( home_url( '/' ) ); ?>">
			<?php bloginfo( 'name' ); ?>
		</a>
	</p>
</footer>

<?php wp_footer(); ?>
</body>
</html>
