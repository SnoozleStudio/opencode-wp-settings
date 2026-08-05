# WordPress Plugin Architecture — Enterprise

Source: WordPress Plugin Handbook. Load this when building plugins.

## Canonical structure

```
plugin-slug/
├── plugin-slug.php          # main file — ONLY file with the plugin header
├── uninstall.php            # guarded by WP_UNINSTALL_PLUGIN
├── languages/               # load_plugin_textdomain path
├── includes/                # classes (class-{name}.php) + shared functions
├── admin/                   # admin-only (still capability-checked)
└── public/                  # front-end code
```

Conditional loading: `if ( is_admin() ) { require_once ...; }` — but `is_admin()` is
NOT an auth check; capability-check inside.

## Main file header

Plugin Name, Plugin URI, Description (<140 chars), Version (semver-compatible with
`version_compare`), Requires at least, Requires PHP, Author, Author URI, License
(GPLv2+ recommended), License URI, Text Domain (slug with dashes), Domain Path
(`/languages`), Network (only if multisite-only), Update URI, Requires Plugins.

## Lifecycle semantics

- **Activation** (`register_activation_hook( __FILE__, 'prefix_activate' )`): defaults,
  options, register CPTs, add rewrite rules, `flush_rewrite_rules()`
- **Deactivation**: clear TEMPORARY data (caches, temp files), `flush_rewrite_rules()`
- **Uninstall** (`register_uninstall_hook` or `uninstall.php`): permanent data removal —
  `delete_option()`, `delete_site_option()`, drop tables
- Deactivation is NOT uninstall — never delete user data on deactivation

## Naming collision prevention

- Prefix everything global: functions `plg_`, classes `Plg_Class`, namespaces,
  options, transients, hooks, tables — ≥4 chars, not a common English word
- Forbidden prefixes: `__`, `_`, `wp_`, `WordPress`, sub-ecosystem prefixes
- `if ( ! function_exists() )` only for shared libraries, not general practice
- One main class pattern: `class Plg_Plugin { public static function init() {...} }`
  `Plg_Plugin::init();`

## Common modules

### CPT/CT (on `init`)
`register_post_type( 'project', array( 'labels' => ..., 'public' => true, 'show_in_rest' => true, ... ) )`
— all labels translated; prefixed names.

### Settings (Settings API)
`register_setting( 'group', 'option_name', array( 'type' => ..., 'sanitize_callback' => ... ) )`;
render via `settings_fields()` + `do_settings_sections()`; never echo raw options.

### AJAX
`add_action( 'wp_ajax_plg_action', ... )` / `wp_ajax_nopriv_` → `check_ajax_referer()` +
`current_user_can()`; always `wp_send_json_*` with `wp_die()`.

### REST (on `rest_api_init`)
```php
register_rest_route(
    'plg/v1',
    '/items/(?P<id>[\d]+)',
    array(
        'methods'             => WP_REST_Server::READABLE,
        'callback'            => 'plg_rest_get_item',
        'permission_callback' => static function () { return current_user_can( 'edit_posts' ); },
        'args'                => array(
            'id' => array(
                'validate_callback' => static fn ( $v ) => is_numeric( $v ),
                'sanitize_callback' => 'absint',
            ),
        ),
    )
);
```
Namespace `{vendor}/{version}`; never `wp`. Errors: `new WP_Error( 'code', 'msg', array( 'status' => 404 ) )`.
JS nonce action: `wp_create_nonce( 'wp_rest' )` localized via `wp_localize_script`.

## Data

- Options: `add_option( $name, $value, '', false )` — autoload false for anything large;
  `get_option( $name, $default )`; `update_option`; `delete_option`; multisite variants
- Transients for cached computed data — never options
- `$wpdb`: only when no API exists; `$wpdb->prefix`; `$wpdb->prepare()` with unquoted
  placeholders (`%s`/`%d`/`%f`/`%i`); create tables on activation, drop on uninstall

## i18n

`load_plugin_textdomain( 'domain', false, dirname( plugin_basename( __FILE__ ) ) . '/languages' )`
on `init`; text domain = slug with dashes; every string through `__`/`_e`/`_n`/`_x` +
escaping variants with domain as last arg; translators comments on placeholders.

## Verification chain

The canonical 4-step chain (build → format:all:check → phpcs → phpstan) lives in
[verification-chain.md](verification-chain.md) — run it, stop at the first red.

## References

- [WordPress Plugin Handbook](https://developer.wordpress.org/plugins/) — the plugin contract: header, lifecycle, admin, security
- [WordPress Coding Standards — PHP](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/) — PHP rules
- [REST API Handbook](https://developer.wordpress.org/rest-api/) — route registration, per-arg callbacks, `WP_Error`
- [WP-CLI](https://wp-cli.org) — install and activation automation
- [Composer](https://getcomposer.org) — dev tooling (WPCS, Pint)
- Internal: [php standards](wordpress-php-standards.md) · [security](wordpress-security.md) · [performance](performance.md)
