---
name: wp-js-standards
description: WordPress JavaScript Coding Standards reference — tabs and spacing, semicolons, braces, const and let over var, camelCase naming with acronym rules, strict equality, single quotes, type checks, switch statements, best practices, ESLint enforcement. Use when writing or reviewing theme/plugin JavaScript, ES modules, or when asked about WordPress JS conventions. Pairs with wp-css-standards and wp-html-standards.
---

# WordPress JavaScript Coding Standards

Distilled from the official WordPress JavaScript Coding Standards (developer.wordpress.org),
which adapts the jQuery style guide. WP differs from jQuery: single quotes, indented
case statements, consistent function-body indentation, spaces after `!`.

## Goal

Write and review JavaScript that follows the WordPress JS Coding Standards,
knowing exactly what ESLint enforces vs what stays review-only.

## When to use

- Writing or reviewing theme/plugin JS (ES modules, components, utilities)
- Answering "what does the WordPress JS standard say about X"

## Code refactoring

- New or updated code must conform and pass lint; refactoring older files to the
  standard is not urgent — **whitespace-only patches to working files are strongly
  discouraged**

## The standard

### Spacing

- **Tabs** for indentation; no trailing whitespace; no whitespace on blank lines
- Lines usually ≤ 80 chars, never > 100 (tabs count as 4)
- `if`/`else`/`for`/`while`/`try` always use braces and multiple lines
- Unary operators (`++`, `--`, `!`) no space next to operand — but `!` gets a
  following space (`! condition`); `,` and `;` no preceding space; `:` after a
  property name no preceding space; ternary `?`/`:` spaced both sides
- No filler spaces in empty constructs: `{}`, `[]`, `fn()`
- Newline at end of file
- Extra spaces inside function-call parens and array/object brackets:
  `foo( arg )`, `arr[ 0 ]`, `object[ property ]` — mirroring the PHP standard
- One property per line for multi-line objects/arrays, trailing comma

### Semicolons

- Always. Never rely on Automatic Semicolon Insertion

### Indentation and line breaks

- Braces on the same line as the statement, closing brace on its own line
- Multi-line statements break **after** operators, not before:
  `'...' +` then the next chunk on the following line
- Long conditionals: each operand on its own line, indented one level from the parens
- Chained method calls: one call per line, first call on its own line from the
  receiver; extra indent when the context changes (`.children()`)

### Variables

- ES2015+: `const` unless reassigned, then `let`; declare at first use — no `var`
- Globals used in a file documented at the top: `/* global passwordStrength:true */`
  (`:true` = defined here, omitted = read-only)
- jQuery via `( function ( $ ) { ... } )( jQuery );` — never assume a global `$`
- Files that add to or modify the global `wp` object access it safely:
  `window.wp = window.wp || {};` at the top — never overwrite existing properties

### Naming

- Variables/functions: camelCase, lowercase first letter, full words
  (`userId`, `getContentHeight`)
- Acronyms all caps mid-name (`currentDOMDocument`); abbreviations camelCase
  (`userId` — "Id" is an abbreviation); at name start respect camelCase casing
  (`domDocument`, class `DOMDocument`)
- Classes/constructors: UpperCamelCase
- Constants never reassigned or mutated: SCREAMING_SNAKE_CASE, top-most scope

### Comments

- Before the code they refer to, preceded by a blank line; capital first letter;
  full stop on sentences; single space after `//`
- JSDoc via `/** */` for documentation comments

### Equality and type checks

- **Strict equality always**: `===` / `!==`, never `==` / `!=`
- Type checks: `typeof x === 'string' | 'number' | 'boolean' | 'object'`;
  arrays via `Array.isArray`; null `x === null`; undefined `typeof x === 'undefined'`
  for globals, `x === undefined` for locals

### Strings

- Single quotes for string literals; escape embedded single quotes

### Switch

- Discouraged generally; when used: `break` per case (except `default`), explicit
  fall-through comments, case indented one tab inside switch, set values in cases
  and return after the switch — never `return` inside a case

### Best practices

- Arrays via `[]` literal; objects via `{}` literal (constructor only for
  prototypes); dot notation unless the key is dynamic
- Cache loop maxes: `for ( i = 0, max = getCount(); i < max; i++ )`
- Iterate jQuery collections only with `$collection.each()`; raw data with native
  iteration — never jQuery for plain objects
- Underscore collection functions (`_.each`, `_.map`, `_.reduce`) for efficient
  readable transforms of large data sets; chain with `_.chain( obj ).keys().map( fn ).value()`
- Type-check with Underscore's `_.isFunction`/`_.isArray`/`_.isUndefined` where
  Backbone/Underscore are already in use

## Enforcement mapping

| Rule | Enforced by |
| ---- | ----------- |
| Tabs, quotes, semicolons, trailing commas, line length | Prettier (`useTabs: true`, `singleQuote`, `semi`) |
| `no-var` (const/let), `===`, no-unused-vars, camelCase, no-shadow, no-nested-ternary, no-console (warn/error allowed) | ESLint `@wordpress/eslint-plugin` (flat config) |
| `document.activeElement` → `ownerDocument` patterns | `@wordpress/no-global-active-element` |
| Globals documentation, loop-cache, type-check idioms, switch discipline | Review-only |

## Rules

- Never introduce `var` or `==` in new code; the lint gate is part of
  `format:all:check` — never bypass it
- Browser globals belong in `eslint.config.mjs` `globals`, not `eslint-disable`
- Bitwise color math in rendering code is a documented deviation
  (`no-bitwise: off` with a rationale comment)

## Output contract

- Written JS: standards-compliant and lint-clean on first pass
- Review findings: `file:line` + rule + fix

## References

- [JavaScript Coding Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/javascript/)
- Internal: [front-end stack](../../docs/frontend-stack.md) (component pattern, ESLint config) ·
  [wp-html-standards](../wp-html-standards/SKILL.md) · [wp-css-standards](../wp-css-standards/SKILL.md)