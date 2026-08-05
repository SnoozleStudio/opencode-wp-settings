---
description: Scaffold a new enterprise-grade WordPress plugin project.
---

Create a new WordPress plugin: $ARGUMENTS

Use the scaffolder agent with templates/plugin/ as the source of truth. Substitute the slug/prefix/namespace/text-domain everywhere, verify the main file header is complete, uninstall.php is guarded by WP_UNINSTALL_PLUGIN, phpcs.xml runs WordPress-Extra + WordPress-Docs + PHPCompatibility, and run composer install + npm install. Report the next commands the user must run.
