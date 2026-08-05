---
name: wp-theme
description: Architect, scaffold, and extend enterprise-grade WordPress classic themes. Use when creating a new theme, adding page sections, building templates, wiring enqueues, or integrating front-end libraries (Vite, Tailwind v4, GSAP, Lenis, Tempus, Three.js, swup). Covers style.css header, template hierarchy, functions.php boot chain, manifest-driven enqueue, and the front-end component pattern.
---

# WordPress Classic Theme — Enterprise Architecture

Classic themes (not block themes) that survive Theme Review. Load
`docs/wordpress-theme-architecture.md` and `docs/frontend-stack.md` for full references.
Deep GSAP API details come from the vendored `gsap-*` skills (official
greensock/gsap-skills) on GSAP-specific requests; their guidance is generic — the
house integration rules in `docs/frontend-stack.md` (Lenis, Tempus, reduced-motion,
manifest enqueue) override it.

## Canonical structure

```
theme-slug/
├── style.css                # theme header ONLY (no styles — Vite handles CSS)
├── functions.php            # boot loader (load-order sensitive)
├── index.php / front-page.php / page.php / single.php / archive.php / 404.php ...
├── template-parts/          # content-{x}.php parts via get_template_part()
├── configure/               # boot modules (utilities, nav-walker, configure, js-css, acf)
├── acf-json/                # ACF field group sync (save + load paths)
├── src/                     # Vite source (scripts/components/*.js, styles/main.css)
├── dist/                    # Vite build output (gitignored)
├── languages/               # load_theme_textdomain path
├── vendor/                  # composer dev tooling (phpcs, pint) — never runtime deps
├── package.json / vite.config.mjs / composer.json / phpcs.xml
└── .husky/pre-commit        # format:all:check + phpcs + phpstan gate
```

## style.css header (required fields)

Theme Name, Theme URI, Author, Description, Version (X.X.X), Requires at least,
Tested up to, Requires PHP, License, License URI, Text Domain (slug **with dashes**),
Tags, Domain Path.

## functions.php boot chain (order matters)

1. `configure/utilities.php` — Vite manifest reader (`ss_get_vite_manifest()` pattern,
   static-cached), nav class filters
2. `configure/nav-walker.php` — `Theme_Slug_Header_Nav_Walker extends Walker_Nav_Menu`
3. `configure/configure.php` — `after_setup_theme`: menus, thumbnails, title-tag, html5,
   textdomain, cleanup (remove emoji/embed/global styles, unused image sizes)
4. `configure/js-css.php` — manifest-driven enqueue on `wp_enqueue_scripts`
5. `configure/acf.php` — `acf-json/` save/load paths + `SS_THEME_DIR_PATH` constant

Each file: `if ( ! defined( 'ABSPATH' ) ) { exit; }` guard; `ss_`-style prefixes;
`function_exists` guards where required.

## Enqueue (manifest-driven, Vite)

- `vite.config.mjs`: `base` = `/wp-content/themes/{slug}/dist/`, `build.manifest: true`,
  entry `src/scripts/main.js`, code-splitting via `rolldownOptions`
- PHP reads the manifest, enqueues the hashed entry with `['strategy' => 'defer']`,
  rewrites tag to `type="module"` via `script_loader_tag`
- Dynamic chunks (`qrcode-*`, three-*) load via runtime `import()` — never enqueue them
- Fonts/CSS preloaded in `header.php` from manifest paths
- Dev: `npm run dev` (Vite server) + `npm run start` (build --watch); PHP changes need a
  browser reload

## Front-end component pattern (JS)

New component in `src/scripts/components/{name}.js`:

```js
export function initComponent() {           // guard: element exists?
  if ( ! document.querySelector( '.selector' ) ) return;
  const prefersReduced = window.matchMedia( '(prefers-reduced-motion: reduce)' ).matches;
  if ( prefersReduced ) return;
  const ctx = gsap.context( () => { /* anims */ } );
  const unsub = Tempus.add( ( { time, deltaTime } ) => { /* loop */ } );
  return () => {                              // cleanup returned for teardown
    ctx.revert();
    unsub();
  };
}
```

Register in `src/scripts/main.js` (init on DOMContentLoaded, collect cleanups).
Heavy work (Three.js, QR): dynamic `import()` + IntersectionObserver.

## Stack defaults (do not invent alternatives)

- Tailwind v4 CSS-first: `@theme` tokens + `@font-face` in `src/styles/main.css`,
  `@source` for PHP template dirs if auto-detection misses them; **no tailwind.config.js**
- Lenis: `autoRaf: false`, driven by Tempus `{ order: -1 }`; `data-lenis-prevent` for
  nested scrollables; reduced-motion gate
- GSAP: `gsap.context()` + revert, `matchMedia` for reduced-motion, `ScrollTrigger.refresh()`
  after fonts/images
- swup (optional): re-init + destroy all libs on `content:replace`

## Verification chain

```
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

## Scaffolding

Greenfield themes → `scaffolder` agent (`templates/theme/`). New sections → the
`build-section` flow inside this skill: read one existing section first, match the house
pattern, ACF fields via `get_field()`, escape at output, verify chain.
