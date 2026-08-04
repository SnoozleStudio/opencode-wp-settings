---
description: Scaffold a new enterprise-grade WordPress classic theme project.
---

Create a new WordPress classic theme: $ARGUMENTS

Use the scaffolder agent with templates/theme/ as the source of truth. Substitute the slug/text-domain everywhere: style.css header (all required fields), functions.php boot chain (utilities → nav-walker → configure → js-css — load-order sensitive), vite.config.mjs base set to /wp-content/themes/{slug}/dist/, acf-json/ wired, package.json + composer.json + phpcs.xml + .husky. Run npm install + composer install, then the verification chain. Report next steps (ACF sync, activation).
