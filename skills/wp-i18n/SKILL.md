---
name: wp-i18n
description: Make WordPress code translation-ready. Use when writing any user-facing string, adding text domains, fixing untranslated output, or preparing a plugin/theme for localization. Enforces the i18n escaping matrix, translators comments, numbered placeholders, and text-domain rules.
---

# i18n — Translation-Ready WordPress Code

Every user-facing string passes through a translation function. No exceptions. Text
domain = plugin/theme slug **with dashes**, passed as the LAST argument, never via
variable/constant.

## Function matrix

| Context | Function |
|---|---|
| Echo text | `esc_html_e( 'Text', 'domain' )` |
| Return text | `esc_html__( 'Text', 'domain' )` |
| Attribute | `esc_attr_e()` / `esc_attr__()` |
| Context (noun vs verb) | `_x( 'Post', 'noun', 'domain' )` / `esc_html_x()` |
| Plural | `_n( 'item', 'items', $count, 'domain' )` |
| Plural + context | `_nx()` |
| Numbers/dates | `number_format_i18n()`, `date_i18n()` |

Never raw `__( )` or `_e()` inside HTML — always the escaping variants.

## String rules

- **No interpolation** — use placeholders: `printf( /* translators: %s: Name */
  esc_html__( 'Welcome, %s', 'domain' ), $name );`
- Multiple placeholders: numbered `%1$s`, `%2$d` **in single quotes** (double quotes
  would interpolate `$s`)
- **Translators comment** must immediately precede the gettext call and start with
  `translators:` — explains every placeholder
- Full sentences, no leading/trailing whitespace, no URLs inside strings, no empty
  strings, no `\r`
- Don't translate markup — translate the text, escape at echo
- Avoid near-duplicate strings (same wording, same punctuation)

## Loading

- Themes: `load_theme_textdomain( 'domain', get_template_directory() . '/languages' )`
  in the `after_setup_theme` setup function
- Plugins: `load_plugin_textdomain( 'domain', false, dirname( plugin_basename( __FILE__ ) )
  . '/languages' )` on `init`
- Header: `Text Domain: domain` + `Domain Path: /languages` in both

## JS strings

- Use `wp.i18n` (`wp_set_script_translations( 'handle', 'domain' )` after enqueue):
  `wp.i18n.__()`, `sprintf()`, `_n()` — never hardcoded UI strings in JS for
  user-facing text

## Audit

Grep for: `__(` / `_e(` without text domain, raw quotes around user-facing text in
templates, interpolated `$var` inside `__('... $var ...')`, missing translators comments
on placeholders. The WPCS `WordPress.WP.I18n` sniff catches most — run phpcs.
