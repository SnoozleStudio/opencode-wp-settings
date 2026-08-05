---
name: wp-performance
description: Optimize and audit WordPress plugin/theme performance — server-side (enqueue discipline, options autoload, transients, query caching) and front-end (bundle splitting, dynamic imports, rAF budget, animation cost). Use when improving page speed, web vitals, or when writing any code that runs on every request.
---

# Performance — WordPress + Front-End

Load `docs/performance.md` for the full reference. Two halves: what runs on the server
every request, and what runs in the browser every frame.

## Server-side (PHP)

- **Enqueue discipline**: only enqueue what the current page needs (conditional tags:
  `is_front_page()`, `is_singular()`, `is_page_template()`); never load admin assets on
  the front end or vice versa; `wp_enqueue_*` only — no hardcoded `<link>`/`<script>`
- **Options**: `autoload: false` for anything large or rarely used (autoloaded options
  load on EVERY request); Transients for cached computed data (not options); never
  `update_option` per request
- **Queries**: use `pre_get_posts` instead of duplicate `WP_Query`; `no_found_rows`,
  `'fields' => 'ids'` where applicable; always `wp_reset_postdata()`; prefer
  `get_posts`/API functions (cached) over raw `$wpdb`
- **Manifest-driven assets**: read Vite manifest once per request (static cache), preload
  fonts, defer module scripts
- No heavy autoload of plugin classes on the front end — load only what the request needs

## Front-end (browser)

- **Bundle discipline**: entry JS imports CSS + core; Three.js / QR / heavy libs behind
  dynamic `import()` chunks; vendor code-split ≤ ~300KB chunks; `chunkSizeWarningLimit`
  tuned in vite config
- **rAF budget**: all animation through Tempus (single loop); gate expensive work on
  `state.budget`; pause loops when elements leave viewport (IntersectionObserver);
  skip frames on low-core machines (`navigator.hardwareConcurrency`)
- **Animation cost**: animate only `transform`/`opacity`; no layout thrash; no
  `will-change: transform` on ancestors of `position: fixed`; avoid forcing repaints
  (filter/blur on large layers)
- **Scroll**: Lenis on native scroll (no transform-based virtual scroll) — cheap and
  sticky-safe; `data-lenis-prevent` for nested scrollables instead of
  `allowNestedScroll`
- **Fonts**: woff2 with `font-display: swap` + `unicode-range` subsets; preload critical
  font files
- **Async CSS**: critical CSS inline/preloaded, rest loaded async with noscript fallback
- **Media**: lazy loading images/video; proper `srcset`/`sizes`

## Audit procedure

1. Server: trace one request path — what's enqueued, which options autoload, query count
   (`Query Monitor` in dev or `save_queries`)
2. Front-end: bundle report (`vite build --report` or analyze dist), dynamic chunks,
   animation loops
3. Report: measured findings only (never fabricate Lighthouse/bundle numbers); flag what
   needs browser profiling
