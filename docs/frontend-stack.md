# Front-End Stack — WordPress + Vite Integration

Load this when writing or reviewing JS/CSS in themes/plugins. Stack: Vite 8 (Rolldown),
Tailwind v4 (CSS-first), GSAP 3.15, Lenis 1.3, Tempus, Three.js, swup (optional).

## Vite 8 for WordPress

- `base`: absolute theme/plugin path — `/wp-content/themes/{slug}/dist/` — or font/asset
  URLs break (learned the hard way)
- `build.manifest: true` → `.vite/manifest.json` consumed by PHP enqueue
- **`rolldownOptions`** is the current key — `build.rollupOptions` is a deprecated alias
  (Vite 8 is Rolldown-based)
- Code splitting: automatic via `import()`; group vendor chunks via
  `rolldownOptions.codeSplitting.groups`; keep chunks ≤ ~300KB
- `build.chunkSizeWarningLimit` (default 500 kB) — raise deliberately for Three.js or
  dynamic-import it instead
- `emptyOutDir: true` default only when `dist/` is inside root (it is — fine)
- Dev server proxy for local WP: `server.proxy: { '/wp-json': { target: 'http://localhost:8080', changeOrigin: true } }`
- Env: only `VITE_`-prefixed vars exposed; use `loadEnv(mode, cwd, '')` at config time
- Node ≥ 20.19

## Tailwind v4 (CSS-first)

- No `tailwind.config.js` — config lives in CSS: `@import "tailwindcss";` +
  `@theme { --color-*; --font-*; ... }` (tokens generate utilities: `--color-mint-500`
  → `bg-mint-500`)
- `@source` for PHP template dirs if auto-detection misses them (WordPress case)
- Custom utilities: `@utility foo { ... }` — compose with variants
- Keyframes go INSIDE `@theme` for `--animate-*`
- `@font-face` with `font-display: swap`, local woff2, `unicode-range` subsets; then
  `--font-*` token → `font-*` utility
- Default colors are oklch; `theme()` function deprecated
- Prettier: `prettier-plugin-tailwindcss` sorts classes (v4: it auto-detects the CSS
  stylesheet)

## Lenis (smooth scroll)

```js
import Lenis from "lenis";
import "lenis/dist/lenis.css";

const lenis = new Lenis({ autoRaf: false });
Tempus.add(({ time }) => lenis.raf(time), { order: -1 });
lenis.on("scroll", ScrollTrigger.update);
```

- Options: `smoothWheel` (true), `lerp` (0.1) or `duration`+`easing`, `wheelMultiplier`,
  `syncTouch` (unstable iOS <16), `anchors`, `autoResize` (true), `overscroll` (true)
- Methods: `raf(time)` (ms), `scrollTo(target, { offset, duration, immediate, force, onComplete })`,
  `start()`, `stop()`, `destroy()`
- Properties: `scroll`, `limit`, `progress` (0–1), `velocity`, `direction`, `isScrolling`
- Nested scrollables: `data-lenis-prevent` (prefer over `allowNestedScroll` — perf cost)
- Lenis runs on NATIVE scroll — `position: sticky` and anchors keep working
- No CSS scroll-snap support (lenis/snap plugin); no smooth over iframes
- **Reduced motion**: gate the whole init behind
  `matchMedia('(prefers-reduced-motion: reduce)')` — Lenis doesn't handle it
- `position: fixed` lags on Safari macOS pre-M1 — use `h-dvh` patterns instead

## Tempus (single rAF manager)

- `Tempus.add(cb, { order = 0, fps = Infinity })` → returns unsubscribe; cb gets
  `state = { time (ms), deltaTime, frame, budget }`
- Order: producers at `order: -1`, renders at `order: 1`
- `Tempus.pause()/play()/restart()`; `Tempus.patch()` routes ALL rAF through Tempus
- Integrations (verbatim patterns):
  - Lenis: `Tempus.add(({ time }) => lenis.raf(time))` — no `* 1000` (both ms)
  - GSAP: `gsap.ticker.remove(gsap.updateRoot); Tempus.add(({ time }) => gsap.updateRoot(time / 1000))`
  - Three: `Tempus.add(() => renderer.render(scene, camera), { order: 1 })`
- Per-callback fps throttle: `{ fps: 30 }` or `{ fps: '50%' }`

## GSAP

- Import: `import gsap from "gsap"` + `import ScrollTrigger from "gsap/ScrollTrigger"`;
  `gsap.registerPlugin(ScrollTrigger, ...)`
- **Cleanup**: wrap all animations in `gsap.context(() => {...}, scope)`; call
  `ctx.revert()` on teardown — the framework-agnostic equivalent of `useGSAP()`
- `gsap.matchMedia()` for per-breakpoint + `(prefers-reduced-motion: reduce)` teardown
- `gsap.ticker` time is in SECONDS — `lenis.raf(time * 1000)` when using the ticker;
  `gsap.ticker.lagSmoothing(0)` with Lenis
- ScrollTrigger: `trigger`, `start` (`"top top"`, `"top bottom-=100px"`), `end` (`"+=500"`,
  `"max"`), `scrub`, `pin` (never animate the pinned element itself; `pinReparent` to
  escape ancestor transforms), `markers`, `toggleActions`, `scroller` for custom
  containers, `onEnter/onLeave/onEnterBack/onLeaveBack`
- Static: `.refresh()` after fonts/images/DOM changes (critical), `.update()` from the
  Lenis scroll event, `.killAll()`, `.batch()`, `.normalizeScroll()`, `.isTouch`
- Conflicts: Lenis on native scroll needs no proxy — just refresh + update. Avoid
  `transform`/`will-change: transform` on ancestors of `position: fixed` elements
- Text plugins: SplitText (`new SplitText(el, { type: 'chars,words,lines' })`, revert
  after), ScrambleTextPlugin (`gsap.to(el, { scrambleText: '...' })`)
- **Vendored skills**: the `gsap-*` skills (greensock/gsap-skills) carry official
  API depth. Their guidance is generic — no WordPress/Vite/Lenis/Tempus. House
  rules in this doc and `wp-theme` override: Lenis (never ScrollSmoother — two
  smooth-scroll libs conflict), Tempus ticker routing, reduced-motion gate,
  manifest enqueue. Refresh them via `npx skills update -a opencode -g`, never edit.
- All plugins (SplitText, MorphSVG, Observer, etc.) are free since the Webflow
  acquisition — install everything from the public `gsap` npm package; no Club
  GSAP membership, no private registry.

## Three.js

- Heavy: always `const THREE = await import("three")` inside an async init (Vite splits
  the chunk, loaded on demand) — never a static import in the entry bundle
- Check `WebGL.isWebGLAvailable()` and render a fallback before init
- Loop: `Tempus.add(() => renderer.render(scene, camera), { order: 1 })` (or
  `renderer.setAnimationLoop`)
- `setPixelRatio(Math.min(devicePixelRatio, 2))`; `powerPreference: 'high-performance'`
- **Dispose everything** on teardown: geometry/material/texture `.dispose()`,
  `renderer.dispose()`; `scene.remove(obj)` + traverse for disposal
- Text: `FontLoader().load('typeface.json')` → `new TextGeometry(text, { font, size, depth, curveSegments })`
- Bloom: `EffectComposer` + `RenderPass` + `UnrealBloomPass(resolution, strength, radius, threshold)` + `OutputPass` (required for correct color space)
- Frame budget: gate expensive passes on `Tempus` `state.budget`

## swup (page transitions, optional)

- `new Swup({ containers: ['#swup'], animationSelector: '[class*="transition-"]', ... })`
- Hooks: `visit:start`, `content:replace`, `visit:end`, `page:view` — **re-init and
  destroy ALL libraries on content replace** (Lenis `.destroy()`, `gsap.context().revert()`,
  Tempus unsubscribes, Three dispose) to avoid leaks and double listeners
- Head scripts/styles aren't re-executed by core — `@swup/head-plugin`,
  `@swup/scripts-plugin`, `@swup/scroll-plugin` as needed
- Sends `X-Requested-With: swup` — detectable server-side
- One scroller: swup-scroll OR Lenis, not both

## Component template (house pattern)

```js
export function initComponent() {
	if ( ! document.querySelector( ".selector" ) ) return;
	if ( window.matchMedia( "(prefers-reduced-motion: reduce)" ).matches ) return;
	const ctx = gsap.context( () => { /* animations */ } );
	const unsub = Tempus.add( ( { time, deltaTime } ) => { /* loop */ } );
	return () => { ctx.revert(); unsub(); };   // cleanup returned for teardown
}
```

Registered in `main.js`: init on DOMContentLoaded, cleanups collected; IntersectionObserver
for lazy/heavy inits; `navigator.hardwareConcurrency <= 4` frame-skipping for heavy loops.

## References

- [Vite — Guide](https://vitejs.dev/guide/) · [Vite — Config reference](https://vitejs.dev/config/) (Rolldown, `rolldownOptions`)
- [Tailwind CSS v4](https://tailwindcss.com/docs) — CSS-first configuration: `@theme`, `@utility`, `@source`
- [GSAP docs](https://gsap.com/docs/) — `gsap.context()`, `matchMedia()`, ScrollTrigger
- [Lenis](https://github.com/darkroomengineering/lenis/blob/main/README.md) — smooth scroll (official README)
- [Tempus](https://github.com/darkroomengineering/tempus/blob/main/README.md) — single rAF manager (official README)
- [Three.js docs](https://threejs.org/docs/) — renderer, textures, disposal
- [swup](https://swup.js.org) — page transitions
- [Node.js](https://nodejs.org) — Vite requires Node ≥ 20.19
- Internal: [theme architecture](wordpress-theme-architecture.md) · [performance](performance.md) · [accessibility](accessibility.md)
