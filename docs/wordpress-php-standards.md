# WordPress PHP Coding Standards — Full Reference

Source: developer.wordpress.org Coding Standards (PHP) + WPCS 3.0. Load this when
writing or reviewing any PHP. The AGENTS.md summary is the floor; this is the ceiling.

## File mechanics

- Full tags only: `<?php` / `?>` — never `<?` or `<?=`
- Multi-line PHP in templates: tags on their own lines; omit the closing tag at EOF
- `require_once` over `include[_once]` (include only warns, leading to cascade failures);
  no parens around the path; one space between keyword and path
- Every file with top-level code: `if ( ! defined( 'ABSPATH' ) ) { exit; }`

## Naming

- Functions/variables/hooks: lowercase `snake_case`; never camelCase; no unnecessary
  abbreviations
- Classes/traits/interfaces/enums: `Capitalized_Words` with underscores, acronyms
  uppercase (`WP_HTTP`, `Walker_Category`)
- Constants: `ALL_CAPS_WITH_UNDERSCORES`
- Files: lowercase, hyphens; class files `class-{name}.php` (one object per file)
- Dynamic hook names: interpolation in double quotes —
  `do_action( "{$new_status}_{$post->post_type}", $post->ID )`
- Namespaces: `Prefix\Module\Sub_Module` (capitalized words, underscores), one per file,
  blank line before/after; **`wp`/`WordPress` reserved for core**; namespacing does NOT
  cover hook names/constants/globals — still prefix them
- `use` order: classes → functions → constants; no leading backslashes
- Parameter names must avoid PHP 8 reserved keywords (named-args hazard)

## Syntax

- Tabs for indentation (spaces only for mid-line alignment)
- Spaces: both sides of operators; inside control-structure parens
  (`foreach ( $foo as $bar ) {`); after commas; `$foo['bar']` no space, `$foo[ $bar ]` space
- Long array syntax `array( ... )` — mandatory (short `[...]` is prohibited)
- Yoda conditions for `==`/`!=`/`===`/`!==` only (constant on left); never Yoda for `<`/`>`
- Braces always used; `elseif` never `else if`; alternative syntax (`if: ... endif;`)
  allowed in templates
- Single quotes unless interpolating; alternate quotes to avoid escaping
- No `extract()`, `eval()`, `create_function()`, `goto`, `@` suppression; no
  short ternary `?:` (exception: `! empty()`); no assignments inside conditionals
- Closures fine as callbacks but **never** as action/filter callbacks
- Switch fall-through from a block must be explicitly commented
- `$wpdb->prepare()` placeholders: `%d` int, `%f` float, `%s` string, `%i` identifier
  (table/column, WP 6.2+); **never quote placeholders**

## OOP

- One class/interface/trait/enum per file, `class-{name}.php`
- Declare all visibility; `var` forbidden; modifier order: `abstract`/`final` →
  visibility → `static` → type
- `new Foo();` always with parens
- Type declarations: `?Type` attached, `: Type|false` no space before colon; avoid
  `array` keyword (use `iterable`); gate features by PHP version

## phpcs configuration (enterprise)

```xml
<?xml version="1.0"?>
<ruleset name="Project">
    <description>Enterprise WordPress standards</description>
    <file>.</file>
    <exclude-pattern>node_modules/*</exclude-pattern>
    <exclude-pattern>vendor/*</exclude-pattern>
    <exclude-pattern>dist/*</exclude-pattern>
    <arg name="extensions" value="php"/>
    <config name="testVersion" value="8.2-"/>
    <rule ref="WordPress-Extra"/>
    <rule ref="WordPress-Docs"/>
    <rule ref="PHPCompatibility"/>
    <rule ref="WordPress.WP.I18n">
        <properties>
            <property name="text_domain" value="your-slug"/>
        </properties>
    </rule>
</ruleset>
```

Rule groups: `WordPress` (all), `WordPress-Core` (PHP standards), `WordPress-Docs`
(phpdoc), `WordPress-Extra` (best practices incl. escaping/sanitization sniffs and a
curated Universal subset, includes Core). Add `PHPCompatibility` (with `testVersion`)
for cross-version checks. Do NOT `ref="Universal"` wholesale: its ruleset is an empty
namespace container, so PHPCS loads every sniff in it — including the mutually
exclusive `Universal.PHP.RequireExitDieParentheses` / `DisallowExitDieParentheses`
pair. Add individual Universal sniffs only when needed. `phpcbf` auto-fixes most
formatting; `WordPress.Utils.I18nTextDomainFixer` is opt-in.
