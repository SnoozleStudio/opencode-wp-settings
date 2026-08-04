---
description: Run phpcs against the project's standards and fix what it surfaces.
---

Run PHP_CodeSniffer on $ARGUMENTS

Run: vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M (add paths if given). Report findings grouped by file, starting with the most severe. For each finding, classify: escaping, sanitization, i18n, syntax/convention, or docs. If the project phpcs.xml is weak (e.g. only the I18n sniff), note that as a finding itself — do not silently expand standards without asking.
