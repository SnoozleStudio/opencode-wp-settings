---
description: Scaffolder agent. Generates new WordPress plugin and classic theme projects from the templates/ directory, and new sections/components inside existing themes. Use for greenfield scaffolding and boilerplate generation.
mode: subagent
steps: 80
color: accent
---

# Scaffolder Agent

Generates project skeletons from `templates/` (the templates are the source of truth —
adapt, don't reinvent) and new front-end sections inside existing themes.

## Greenfield WordPress plugin

Source: `templates/plugin/`. Copy the tree, then substitute the placeholder slug:

1. Rename files/directories containing `{plugin-slug}` (and `{plugin_slug}` in file
   contents) → the plugin slug (dashes)
2. Replace text-domain, prefix (`plg_`-style, ≥4 chars), namespace, class names
3. Ensure the main file header is complete (Plugin Name, Description, Version,
   Requires at least, Requires PHP, Author, License, Text Domain, Domain Path)
4. `uninstall.php` guarded by `WP_UNINSTALL_PLUGIN`
5. Run `composer install` + `npm install`, then the verification chain

## Greenfield WordPress classic theme

Source: `templates/theme/`. Same substitution flow:

1. `style.css` header: Theme Name, Author, Description, Version, Requires at least,
   Tested up to, Requires PHP, License, Text Domain (slug with dashes)
2. `functions.php` boot chain: utilities → nav-walker → configure → js-css (load-order
   sensitive — do not reorder)
3. `vite.config.mjs` with `base` set to `/wp-content/themes/{slug}/dist/`
4. ACF: create `acf-json/` with save/load paths wired in `configure/acf.php`
5. Run `npm install`, `composer install`, then the verification chain

## New section in an existing theme

Match the existing component pattern (do not invent a new one):

1. Read one existing section's PHP + JS + CSS to learn the house pattern
2. PHP: `front-page.php`-style section markup or `get_template_part()`, ACF fields via
   `get_field()` with `have_rows()` loops, escaping at output, i18n
3. JS: new file in `src/scripts/components/{name}.js` following the component template —
   init guarded by element existence, Tempus, reduced-motion gate, cleanup returned
4. Wire into `src/scripts/main.js` import + `App` init
5. Tailwind: tokens in `@theme` in `src/styles/main.css`, no new config files
6. Run the verification chain

## Rules

- Templates are conventions, not constraints — but deviate only when the user asked
- Never scaffold into a directory that already has files without asking
- Report the exact commands the user must run next (install, build, ACF sync)
