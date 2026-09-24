---
name: wp-css-standards
description: WordPress CSS Coding Standards reference — structure, selector naming, property ordering, values, vendor prefixes, media queries, commenting, best practices. Use when writing or reviewing theme/plugin CSS, Tailwind v4 tokens and custom utilities, or when asked about WordPress CSS conventions. Pairs with wp-js-standards and wp-html-standards.
---

# WordPress CSS Coding Standards

Distilled from the official WordPress CSS Coding Standards (developer.wordpress.org).
The purpose: stylesheets look like one person wrote them — readable, meaningful,
consistent. Third-party libraries are exempt.

## Goal

Write and review CSS that follows the WordPress CSS Coding Standards, mapping each
rule to what the toolchain enforces automatically vs what stays review-only.

## When to use

- Writing or reviewing CSS in a theme/plugin (handwritten CSS, Tailwind `@theme`
  tokens, custom `@utility` blocks)
- Answering "what does the WordPress CSS standard say about X"
- Auditing a stylesheet against the standard

## The standard

### Structure

- **Tabs, not spaces** for indentation (one tab per property)
- Two blank lines between sections; one blank line between blocks in a section
- Each selector on its own line, ending in a comma or `{`; property-value pairs on
  their own line, one tab indented, ending in `;`; closing brace flush with the
  opening selector

### Selectors

- Lowercase, words separated by **hyphens** — never camelCase, never underscores
- Human-readable names that describe what they style; no cryptic ids (`#c1-xr`)
- Attribute selectors use **double quotes**: `input[type="text"]`
- No over-qualified selectors: `.container`, not `div.container`
- Exercise specificity judgment: location-specific selectors clutter fast

### Properties

- Colon then a space: `color: #fff;`
- All properties and values lowercase (except font names and vendor-specific props)
- Colors: hex or `rgba()` when opacity is needed; avoid `rgb()` and uppercase;
  shorten `#FFFFFF` → `#fff`
- Use shorthand for `background`, `border`, `font`, `list-style`, `margin`,
  `padding` (except when overriding)
- **Property ordering** — grouped, meaningful order, not random:
  1. Display
  2. Positioning
  3. Box model
  4. Colors and typography
  5. Other
  - TRBL order (top/right/bottom/left) for `margin`/`padding`-style properties;
    corner specifiers top-left, top-right, bottom-right, bottom-left
  - Alphabetical ordering is the accepted alternative
- Fixed dimensions only when a fluid solution isn't acceptable

### Vendor prefixes

- Autoprefixer handles prefixes in build (longest `-webkit-` → shortest
  unprefixed) — do not hand-maintain prefix blocks

### Values

- Space before the value, after the colon; no padding inside parens; always end in `;`
- Double quotes only when needed (font names with spaces, `content`)
- Font weights numeric: `400` not `normal`, `700` not `bold`
- Zero values without units (unless needed, e.g. `transition-duration`)
- **Unit-less line-height** (unless a specific pixel value is required)
- Leading zero for decimals, including `rgba()`: `rgba(0, 0, 0, 0.5)`
- Long multi-part values (`box-shadow`, `text-shadow`) on newlines, indented one
  level, including before the first value

### Media queries

- Grouped at the bottom of the stylesheet (exception: huge sectioned files like
  wp-admin.css)
- Rule sets inside media queries indented one level in
- Test above and below every breakpoint

### Commenting

- Comment liberally; long comments break at 80 characters
- Table of contents with index numbers (`1.0`, `1.1`) for long stylesheets
- Section headers: `/** … */` with blank lines around; inline comments directly
  above the rule they describe

### Best practices

- Remove code before adding more when fixing an issue
- No magic numbers (`.box { margin-top: 37px }` is a smell)
- Target the element itself, not "finding it" through parents
- `height` only for external content (images); otherwise `line-height`
- Don't restate default property/value combinations (`display: block` on a div)

## Tailwind v4 applicability

The property-ordering and media-query grouping rules target handwritten core
stylesheets — with Tailwind v4 CSS-first they are mostly moot (utility classes).
The rules that still apply: lowercase names, hex/rgba colors, `@theme` tokens in
lowercase hex, tabs, no magic numbers in `@utility` blocks.

## Enforcement mapping

| Rule group | Enforced by |
| ---------- | ----------- |
| Tabs, semicolons, quotes, no trailing whitespace | Prettier (`useTabs: true`, `tabWidth: 4` in `.prettierrc`) |
| Lowercase, hex/rgba, shorthand, ordering, magic numbers, over-qualification | Review-only (no stylelint in the stack) |
| Tailwind class sorting | `prettier-plugin-tailwindcss` |

## Rules

- Never bypass Prettier for CSS files (tabs are the WordPress standard)
- A CSS-only change still runs the verification chain when the repo is gated
- Flag magic numbers and fixed dimensions in review with file:line

## Output contract

- Review findings: `file:line` + the specific rule violated + suggested fix
- Written CSS: standards-compliant on first pass; if a rule is intentionally
  deviated from, say so and why

## References

- [CSS Coding Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/css/)
- Internal: [front-end stack](../../docs/frontend-stack.md) (Vite/Tailwind integration) ·
  [wp-html-standards](../wp-html-standards/SKILL.md) · [wp-js-standards](../wp-js-standards/SKILL.md)