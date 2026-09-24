---
name: wp-php-standards
description: WordPress PHP Coding Standards reference — full-tag PHP, snake_case prefixed naming, tabs, long arrays, Yoda conditions, escaping and sanitization, $wpdb prepare, i18n, one class per file, phpcs configuration. Use when writing or reviewing theme/plugin PHP, or when asked about WordPress PHP conventions, escaping, or the WPCS gate. Owns the deep reference in docs/wordpress-php-standards.md.
---

# WordPress PHP Coding Standards

The full reference lives in `docs/wordpress-php-standards.md` — load it when writing
or reviewing PHP. This skill is the routing entry point and carries the floor that
must never be violated (mirrors AGENTS.md).

**Scope** (umbrella page): the standards are mandatory for WordPress Core and
recommended for themes/plugins; third-party libraries are exempt even when
integrated. "Coding style" may differ for themes/plugins, but the
interoperability, translatability, and security best practices are not optional.

## Goal

Write and review PHP that passes the WordPress Coding Standards gate (phpcs) —
surviving Theme/Plugin Review from the first file, on PHP 8.2+.

## When to use

- Writing or reviewing theme/plugin PHP
- Answering "what does the WordPress PHP standard say about X"
- Any question about escaping, sanitization, naming, or the phpcs gate

## The standard (floor)

### File mechanics

- Full tags only (`<?php` / `?>`), never `<?` or `<?=`; closing tag omitted at EOF
- Every file with top-level code: `if ( ! defined( 'ABSPATH' ) ) { exit; }`
- `require_once` over `include[_once]`; no parens around the path

### Naming & structure

- Functions/variables/hooks: lowercase `snake_case`, prefixed (≥4 chars, e.g.
  `snoozle_`) — never `wp_`, `__`, `_`
- Classes: `Class_Name`, one class per file, `class-{name}.php`;
  namespaces `Prefix\Module\Sub_Module`; `wp`/`WordPress` reserved
- Constants: `ALL_CAPS_WITH_UNDERSCORES`
- Options, transients, hook names: all prefixed

### Syntax

- **Tabs**; spaces inside control-structure parens; `array( ... )` long syntax
  (short `[...]` prohibited); Yoda conditions for `==`/`!=`/`===`/`!==`
- Braces always; `elseif` never `else if`; single quotes unless interpolating
- No `extract()`, `eval()`, `create_function()`, `goto`, `@` suppression; no
  short ternary `?:` (except `! empty()`); no assignments in conditionals
- Closures never as action/filter callbacks (can't be removed)
- `$wpdb->prepare()` with unquoted `%s`/`%d`/`%f`/`%i` — never concatenated SQL

### OOP

- One object per file; declared visibility (no `var`); modifier order
  `abstract/final` → visibility → `static` → type; `new Foo();` with parens
- `?Type` attached; `: Type|false` no space before the colon

### Security (escape at output, sanitize at input)

- Output: `esc_html()` text, `esc_attr()` attributes, `esc_url()` URLs (never
  `esc_attr( $url )`), `esc_textarea()`, `wp_kses_post()` trusted HTML,
  `esc_html_e()`/`esc_attr_e()` for i18n
- Input: `wp_unslash()` request data first, then sanitize
  (`sanitize_text_field()`, `absint()`, `sanitize_email()`, `sanitize_key()`);
  validate before sanitize (safelists with `in_array( $x, $allowed, true )`)
- CSRF: `wp_nonce_field()`/`check_admin_referer()`/`check_ajax_referer()` on every
  state-changing form; nonces are NOT authorization — pair with
  `current_user_can()`; `is_admin()` is not an auth check
- Redirects: `wp_safe_redirect()` for user-influenced URLs

### i18n

- Every user-facing string through a translation function with the text domain
  as LAST argument; escape + translate for attributes (`esc_attr__()`)
- Translators comments with numbered placeholders

### Hooks

- Custom hooks prefixed and documented with a full DocBlock above
  `do_action()`/`apply_filters()`; filters have no side effects
- Core hook timing: `init` for CPTs/rewrites, `wp_enqueue_scripts`,
  `after_setup_theme` for theme setup

## Enforcement

- **phpcs**: `WordPress-Extra` + `WordPress-Docs` + `PHPCompatibility` + the two
  WPCS 3.x opt-ins (`ValidatedSanitizedInput`, `PrefixAllGlobals` with the
  `prefixes` property) — the templates ship this in `phpcs.xml`
- **pint**: formatter; phpcs is the style authority (pint.json disables the
  conflicting rules)
- **phpstan**: level 8 with `szepeviktor/phpstan-wordpress` (+ ACF stubs in themes)
- Chain: build → format:all:check → phpcs → phpstan, stop at the first red

## Rules

- Never write unescaped output, raw SQL, or missing capability checks
- Never commit code that fails the verification chain
- `setup_postdata()` does NOT set the global `$post` (WP 7.x) — pass posts
  explicitly to `get_the_title( $p )`, `get_field( 'name', $id )`

## Output contract

- Written PHP: chain-green on first pass (format, phpcs 0 errors, phpstan level 8)
- Review findings: `file:line` + rule + fix

## References

- [PHP Coding Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/)
- Internal: [full PHP reference](../../docs/wordpress-php-standards.md) ·
  [security](../../docs/wordpress-security.md) · [plugin architecture](../../docs/wordpress-plugin-architecture.md) ·
  [theme architecture](../../docs/wordpress-theme-architecture.md) · [verification chain](../../docs/verification-chain.md)