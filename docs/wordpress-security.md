# WordPress Security — Doctrine and Checklists

Source: developer.wordpress.org Security APIs. Load this before writing or reviewing
anything that touches input, output, or authorization.

## Doctrine

1. Never trust user input — users, third-party APIs, **even your own database**
2. Escape as late as possible (at the point of output)
3. Sanitization is okay; **validation/rejection is better**
4. Never assume anything; rely on the WordPress API

## Escaping matrix (output — escape at echo time, never at store)

| Function | Context |
|---|---|
| `esc_html()` | Text inside an HTML element |
| `esc_attr()` | HTML attribute values |
| `esc_url()` | URLs in any attribute (`src`, `href`) — never `esc_attr( $url )` |
| `esc_url_raw()` | Storing a URL in the DB |
| `esc_textarea()` | `<textarea>` content |
| `esc_js()` | Inline JS contexts |
| `wp_kses_post()` | Trusted-HTML post content |
| `wp_kses( $html, $allowed )` | Non-trusted HTML with an explicit allowlist |
| `(int)` / `absint()` / `(float)` | Numeric output |

Rules:
- Escape the whole string, never fragments (don't split `esc_attr` around concatenation)
- `wp_localize_script()` values need no escaping (WP handles it); `wp_json_encode()` for
  JSON in data attributes
- When late escaping is impossible, store variables postfixed `_escaped`/`_safe`/`_clean`

## Sanitization (input)

- `wp_unslash()` request data FIRST, then sanitize — always
- Check `isset()` / `empty()` before touching superglobals
- Functions: `sanitize_text_field()`, `sanitize_textarea_field()`, `sanitize_email()`,
  `sanitize_key()`, `sanitize_title()`, `sanitize_file_name()`, `sanitize_html_class()`,
  `sanitize_hex_color()`, `absint()`, `sanitize_url()`
- **Validate before sanitize**: safelists with strict checks — `1 === $input`,
  `in_array( $x, $allowed, true )`, `ctype_alnum()`, `preg_match()`, format correction
  (`(int)`, `sanitize_title`). Blocklists are almost always wrong

## Nonces (CSRF)

- Purpose: CSRF protection only. NOT auth, NOT authorization, NOT access control —
  **always pair with `current_user_can()`**; assume nonces can be compromised
- Create: `wp_nonce_field( 'action' )` (forms), `wp_nonce_url( $url, 'action' )` (links),
  `wp_create_nonce( 'action' )` (AJAX/localize)
- Verify: `check_admin_referer( 'action' )` (admin forms, dies 403),
  `check_ajax_referer( 'action' )` (AJAX), `wp_verify_nonce( $nonce, 'action' )` (general)
- Action strings as specific as possible — include IDs: `'trash-post_' . $post->ID`
- Guests share user ID 0 — hook `nonce_user_logged_out` for session-unique nonces on
  critical guest actions

## Authorization

- `current_user_can( 'capability' )` before every privileged action
- `is_admin()` is NOT an auth check
- Role hierarchy: Administrator inherits everything down to Subscriber
- Wrap destructive front-end registrations in capability checks on `plugins_loaded`
- Redirects: `wp_safe_redirect()` for user-influenced URLs

## SQL injection

- If a WP function exists, use it (`get_post_meta`, `WP_Query`, `get_posts` first)
- Otherwise `$wpdb` + `$wpdb->prepare()` with **unquoted** placeholders:
  `$wpdb->get_var( $wpdb->prepare( "SELECT x FROM t WHERE foo = %s AND status = %d", $name, $status ) )`
- Never concatenate values into SQL

## File & system safety

- `validate_file()`, `wp_handle_upload()` with mime checks
- No `file_get_contents` on user-influenced URLs; no `exec`/`shell_exec`/`system`/
  `eval`/`create_function`/`extract`
- Secrets: never in code/options/i18n strings — `wp-config.php` constants or env vars

## Plugin/theme contract

- ABSPATH guard on every file with top-level code
- `uninstall.php` guarded by `WP_UNINSTALL_PLUGIN`; delete options via
  `delete_option()`, tables via `DROP TABLE IF EXISTS {$wpdb->prefix}x`
- `function_exists`/`class_exists` wrappers only for shared libraries

## REST API

- `permission_callback` on every non-public route (`true` or `WP_Error` with 401)
- Per-arg `validate_callback` (before) + `sanitize_callback`; `enum` for safelists
- Return `WP_Error` with machine-readable codes + `status`
- AJAX nonce action is literally `'wp_rest'`: `wp_create_nonce( 'wp_rest' )` via
  `wp_localize_script`

## Audit checklist (security-auditor agent)

XSS via escaping matrix / SQLi via prepare / CSRF via nonces / privilege escalation via
caps / REST exposure / upload safety / options autoload bloat / secrets in git history /
debug output left in / `esc_attr( $url )` pattern / `echo $_GET` chains /
`update_option` per request.

## References

- [Common APIs Handbook — Security](https://developer.wordpress.org/apis/handbook/security/) — the authoritative WP security doctrine
- [Validating Data](https://developer.wordpress.org/apis/handbook/security/data-validation/) — validate before sanitize
- [Sanitizing Data](https://developer.wordpress.org/apis/handbook/security/sanitizing/) — the sanitization functions
- [Escaping Data](https://developer.wordpress.org/apis/handbook/security/escaping/) — the escaping matrix in full
- [Nonces](https://developer.wordpress.org/apis/handbook/security/nonces/) — CSRF protection
- [OWASP Top Ten](https://owasp.org/www-project-top-ten/) — the broader threat model
- Internal: [php standards](wordpress-php-standards.md) · [plugin architecture](wordpress-plugin-architecture.md) · [theme architecture](wordpress-theme-architecture.md)
