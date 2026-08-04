---
description: Build a new section (or extend an existing one) in the current theme. Matches the house pattern, ACF-driven, verified.
---

Build a section: $ARGUMENTS

Follow the wp-theme skill section flow: first read one existing section (PHP + JS + CSS) to learn the house pattern. Then: PHP markup (get_template_part or section markup) with ACF fields via get_field()/have_rows(), escaping at output, i18n; JS component in src/scripts/components/ (element guard, Tempus, reduced-motion gate, cleanup returned), wired into main.js; Tailwind tokens in @theme. Run the verification chain before reporting done. Note what needs browser validation.
