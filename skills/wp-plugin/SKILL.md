---
name: wp-plugin
description: Architect, scaffold, and extend enterprise-grade WordPress plugins. Use when creating a new plugin, adding plugin features (CPTs, settings pages, REST routes, admin/public split), or reviewing plugin structure. Covers file structure, main-file headers, activation/deactivation/uninstall semantics, options and transients discipline, REST API registration, and the WPCS verification chain.
---

# WordPress Plugin — Enterprise Architecture

Build plugins that survive Plugin Review: correct contract semantics, no namespace
pollution, enterprise-grade security. Load `docs/wordpress-plugin-architecture.md` and
`docs/wordpress-php-standards.md` for the full reference.

## Canonical structure

```
plugin-slug/
├── plugin-slug.php          # main file — ONLY file with the plugin header
├── uninstall.php            # guarded by WP_UNINSTALL_PLUGIN; permanent data removal
├── languages/               # load_plugin_textdomain path
├── includes/                # classes + shared functions (class-{name}.php, one per file)
├── admin/                   # admin-only code (still capability-checked)
└── public/                  # front-end code
```

## Non-negotiables

1. **Prefix everything** — functions `plg_`, classes `Plg_Class`, namespaces
   `Prefix\Module`, options/transients/hook names all prefixed (≥4 chars). Never `wp_`,
   `__`, `_` prefixes. `function_exists` only for shared libraries.
2. **Lifecycle contract** — activation: defaults, CPTs, `flush_rewrite_rules()`.
   Deactivation: temp data + flush rewrites. **Deactivation is NOT uninstall** —
   permanent data removal only in `uninstall.php`.
3. **Main file header** — Plugin Name, Description, Version, Requires at least,
   Requires PHP, Author, License, Text Domain (slug with dashes), Domain Path.
4. **Security** — escaping matrix at output, `wp_unslash` before sanitize, nonces paired
   with `current_user_can()`, `$wpdb->prepare()`, ABSPATH guard on every file with
   top-level code.
5. **i18n** — every string translated, text domain last arg, translators comments.
6. **Data** — Options API with `autoload: false` for large data; Transients for cached
   computed data; settings via Settings API (`register_setting`).
7. **REST** — register on `rest_api_init`; namespace `{vendor}/{version}`;
   `permission_callback` on every non-public route; `validate_callback` +
   `sanitize_callback` per arg; `WP_Error` with machine-readable codes + status.

## Common modules

- **CPT/CT registration**: `init` hook, prefixed names, `register_post_type` args with
  `show_in_rest`, labels translated
- **Admin settings**: Settings API, `register_setting` with sanitize callback, nonce via
  `settings_fields`
- **AJAX (classic)**: `wp_ajax_` / `wp_ajax_nopriv_` with `check_ajax_referer` + capability
- **REST**: read model, `WP_REST_Response`, `rest_ensure_response`

## Verification chain

```
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
```

## Scaffolding

For greenfield plugins, delegate to the `scaffolder` agent (`templates/plugin/` is the
source of truth — adapt, don't reinvent).
