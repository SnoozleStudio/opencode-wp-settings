# WordPress Classic Theme Architecture

Source: WordPress Theme Handbook + WPCS. Load this when building themes.

## style.css header (required)

```
Theme Name, Theme URI, Author, Author URI, Description, Version (X.X.X),
Requires at least (X.X), Tested up to (X.X), Requires PHP (X.X),
License, License URI, Text Domain (slug WITH dashes), Tags, Domain Path
```

Child themes add `Template: parent-slug`. Minimum theme: `index.php` + `style.css`.

## Template hierarchy (first match wins)

- Front: `front-page.php` → (posts: `home.php` → `index.php`) / (static: `page.php` → `index.php`)
- Single: `single-{post_type}-{slug}.php` → `single-{post_type}.php` → `single.php` →
  `singular.php` → `index.php`
- Page: custom template → `page-{slug}.php` → `page-{id}.php` → `page.php` →
  `singular.php` → `index.php`
- Archive: `category-{slug}.php` → `category-{id}.php` → `category.php` → `archive.php`
  → `index.php` (same shape for tag/taxonomy/date/author/CPT archives)
- Search `search.php` → `index.php`; 404: `404.php` → `index.php`
- Partials: `get_template_part( 'template-parts/content', 'post' )`

## functions.php

- Setup on `after_setup_theme`: `load_theme_textdomain()`, `add_theme_support()` —
  `post-thumbnails`, `title-tag`, `html5`, `custom-logo`, `automatic-feed-links`;
  `register_nav_menus()`
- `$content_width` global (classic themes only)
- Prefix ALL functions/classes with the theme slug
- Feature-vs-plugin rule: functionality that should exist regardless of the theme
  belongs in a PLUGIN

## Boot-chain pattern (enterprise)

`functions.php` is a loader only, order is load-order-sensitive:

1. `configure/utilities.php` — manifest reader, nav class filters
2. `configure/nav-walker.php` — `Theme_Slug_Header_Nav_Walker extends Walker_Nav_Menu`
   (numbered items, `aria-current="page"`)
3. `configure/configure.php` — `after_setup_theme`, menus, cleanup
4. `configure/js-css.php` — enqueues (manifest-driven)
5. `configure/acf.php` — `acf-json/` save/load paths

Each file: ABSPATH guard, prefixed functions, `function_exists` guards.

## Enqueue discipline

- Never hardcode `<link>`/`<script>` in header.php — use the API on `wp_enqueue_scripts`
  (front) / `admin_enqueue_scripts` (admin)
- `wp_enqueue_script( $handle, $src, $deps, $ver, array( 'in_footer' => true, 'strategy' => 'defer' ) )`
  — `$args` array since WP 6.3; defer preserves order, async does not; WP may downgrade
  strategies based on dependency tree
- Conditional loading: `is_singular()`, `is_front_page()`, `is_page_template()` — only
  load what the page needs; one enqueue function per context
- Version assets for cache-busting (`$ver`); `get_template_directory_uri()` for parent,
  `get_stylesheet_directory_uri()` for child-aware
- JS i18n: `wp_set_script_translations( 'handle', 'textdomain' )`
- Prefer WP-registered handles (`jquery`, `comment-reply`, `wp-i18n`, `wp-api`) over
  bundling your own

## Vite manifest-driven enqueue

- `vite.config.mjs`: `base: '/wp-content/themes/{slug}/dist/'`, `build.manifest: true`,
  entry `src/scripts/main.js`, `emptyOutDir: true`
- PHP: parse `.vite/manifest.json` once (static-cached), enqueue hashed entry files
- Rewrite the script tag to `type="module"` via `script_loader_tag` filter
- Dynamic chunks load via runtime `import()` — never enqueue them
- Dev: `npm run dev`; PHP changes verified by browser reload

## Accessibility (theme minimums)

Skip link in `wp_body_open()` (visible on keyboard focus); semantic landmarks; logical
heading hierarchy; descriptive link text; `aria-current="page"` on active nav; images
with alt (decorative `alt=""`); every input labeled (placeholder is NOT a label);
contrast 4.5:1; usable at 200% zoom; keyboard-operable menus/modals; focus styles
visible; content usable with JS disabled (`<noscript>` fallbacks).

## Verification chain

```
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
```
