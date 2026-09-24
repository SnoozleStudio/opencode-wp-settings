---
name: wp-html-standards
description: WordPress HTML Coding Standards reference — W3C validation, self-closing elements, attribute quoting, lowercase tags, tabs indentation, PHP and HTML mixing. Use when writing or reviewing theme templates, markup in PHP files, or when asked about WordPress HTML conventions. Pairs with wp-css-standards and wp-js-standards.
---

# WordPress HTML Coding Standards

Distilled from the official WordPress HTML Coding Standards (developer.wordpress.org).

## Goal

Write and review HTML that follows the WordPress HTML Coding Standards — valid,
escaped, tab-indented markup that plays well with PHP templates.

## When to use

- Writing or reviewing template markup in theme/plugin PHP files
- Reviewing rendered HTML for standard compliance
- Answering "what does the WordPress HTML standard say about X"

## The standard

### Validation

- All pages verified against the W3C validator — well-formed markup catches
  automation-testable problems; not a substitute for manual review

### Self-closing elements

- Forward slash with **exactly one space** before it: `<br />` — never `<br/>`

### Attributes and tags

- All tags and attributes **lowercase**
- Attribute values lowercase when machine-interpreted (`content-type`);
  proper title capitalization for human-readable data (link titles)
- Attributes always quoted (unquoted attributes are a security vulnerability)

### Quotes

- Every attribute has a value, single or double quoted:
  `<input type="text" name="email" disabled="disabled" />`
- Boolean attributes: value omitted — `disabled`, never `disabled="true"`
  (`true`/`false` are invalid on boolean attributes)

### Indentation

- **Tabs, not spaces**; indentation reflects logical structure
- Mixing PHP and HTML: indent PHP blocks to match surrounding HTML; closing PHP
  blocks at the same indentation as opening

```php
<?php if ( ! have_posts() ) : ?>
<div id="post-1" class="post">
    <h1 class="entry-title">Not Found</h1>
    <?php get_search_form(); ?>
</div>
<?php endif; ?>
```

## Enforcement mapping

| Rule | Enforced by |
| ---- | ----------- |
| Tabs, quoting, trailing whitespace | Prettier HTML (`useTabs: true`) |
| Mixed PHP/HTML indentation, embedded PHP tag layout | WPCS `Squiz.PHP.EmbeddedPhp` (via phpcs) |
| Lowercase tags/attributes | Prettier HTML (normalizes) |
| W3C validation | Review + validator (no automated gate) |
| Escaping of dynamic output | WPCS `WordPress.Security.EscapeOutput` (esc_html/esc_attr/esc_url at output) |

## Rules

- Never write unescaped output in markup — every dynamic value passes through the
  escaping matrix (`esc_html`/`esc_attr`/`esc_url`/`wp_kses_post`)
- Boolean attributes without values; self-closing with the space
- Keep markup valid even without JS (content usable `<noscript>`)

## Output contract

- Templates written: valid HTML5, tabs, all output escaped at echo time
- Review findings: `file:line` + violated rule + fix

## References

- [HTML Coding Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/html/)
- Internal: [wp-php-standards](../wp-php-standards/SKILL.md) (escaping + template rules) ·
  [wp-css-standards](../wp-css-standards/SKILL.md) · [front-end stack](../../docs/frontend-stack.md)