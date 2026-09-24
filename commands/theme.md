---
description: Scaffold a new enterprise-grade WordPress classic theme project.
---

Create a new WordPress classic theme: $ARGUMENTS

Use the scaffolder agent with templates/theme/ as the source of truth. Substitute the slug/text-domain everywhere: style.css header (all required fields), functions.php boot chain (utilities → nav-walker → configure → js-css → acf — load-order sensitive; acf.php ships always, only acf-json/ is optional), vite.config.mjs base set to /wp-content/themes/{slug}/dist/, phpcs.xml (WordPress-Extra + Docs + PHPCompatibility + ValidatedSanitizedInput + PrefixAllGlobals with the {prefix} prefixes property + acf_esc_html escaping), eslint.config.mjs (flat, @wordpress/eslint-plugin), .github/workflows/ci.yml, package.json + composer.json + .husky. Run npm install + composer install, then the verification chain. Report next steps (ACF sync, activation).