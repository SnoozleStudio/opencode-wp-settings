# Performance — WordPress + Front-End

Load this when optimizing or writing request-path code. Two halves: server (every
request) and browser (every frame).

## Server-side (PHP)

### Enqueue discipline
- Only enqueue what the current page needs: `is_front_page()`, `is_singular()`,
  `is_page_template()`, `is_admin()` — one enqueue function per context
- Never load admin assets on the front end or vice versa
- `wp_enqueue_*` only — no hardcoded `<link>`/`<script>` in templates
- Strategy `defer` for module scripts; conditional `comment-reply` etc.

### Options & transients
- `add_option( ..., false )` (autoload: false) for anything large/rarely used —
  autoloaded options load on EVERY request
- Transients for cached computed data — never options; never `update_option` per request
- Object cache / `wp_cache_*` for repeated lookups

### Queries
- `pre_get_posts` to modify the main query instead of duplicate `WP_Query`
- `no_found_rows => true`, `'fields' => 'ids'` where applicable
- Always `wp_reset_postdata()` after custom query loops
- Prefer API functions (in-memory cached) over raw `$wpdb`
- Lazy-load heavy data; paginate with `paged`

### Build & assets
- Read the Vite manifest once per request (static-cached)
- Preload critical fonts (woff2, `font-display: swap`); async-load non-critical CSS with
  `<noscript>` fallback
- Version assets for cache-busting

## Front-end (browser)

### Bundle discipline
- Entry imports CSS + core JS only; Three.js / QR / heavy libs behind dynamic
  `import()` chunks; vendor groups ≤ ~300KB; raise `chunkSizeWarningLimit` deliberately
- IntersectionObserver-based init for below-fold components

### Frame budget (rAF)
- One loop: Tempus; gate expensive work on `state.budget` (ms left in frame)
- Pause/unsubscribe loops when elements leave viewport (IntersectionObserver)
- Frame-skip on low-core machines: `navigator.hardwareConcurrency <= 4`
- FPS-throttle non-critical callbacks (`{ fps: 30 }`)

### Animation cost
- Animate only `transform`/`opacity` (compositor); never layout properties
- No `* { transition: all }`; no forced reflows in loops (read-then-write batching)
- Avoid `filter`/`blur` on large layers; no `will-change: transform` on ancestors of
  `position: fixed`
- Lenis on native scroll (cheap, sticky-safe); `data-lenis-prevent` over
  `allowNestedScroll` (per-DOM-check cost)

### Media
- `<img loading="lazy">`, `srcset`/`sizes`; video lazy + preload metadata
- `content-visibility: auto` for long off-screen sections where safe

## Audit procedure

1. Server: trace one request — what's enqueued (Query Monitor or inspect HTML), which
   options autoload (`SELECT option_name FROM wp_options WHERE autoload='yes'`), query
   count (`save_queries`), transients hit
2. Front-end: `vite build` output analysis (chunk sizes, dynamic chunks), animation loop
   count, DOM mutations per frame (devtools)
3. Report measured findings only — never fabricate Lighthouse/bundle numbers; flag what
   needs browser profiling
