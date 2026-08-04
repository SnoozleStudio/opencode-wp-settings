---
name: wp-accessibility
description: Enforce WCAG 2.2 AA and WordPress accessibility-ready standards in themes, plugins, and front-end work. Use when building or reviewing templates, menus, forms, modals, animations, or any UI. Loads the accessibility checklist and audits markup for contrast, keyboard operability, semantics, ARIA, focus, and reduced motion.
---

# Accessibility — WCAG 2.2 AA

Load `docs/accessibility.md` for the full checklist. Every theme/plugin ships accessible —
it is not optional.

## Template checklist (PHP)

- **Skip link**: first element in `wp_body_open()`, visually hidden until keyboard focus
- **Landmarks**: `<header>`, `<nav>`, `<main>`, `<footer>`; `aria-current="page"` on active
  nav items (nav walkers)
- **Headings**: logical hierarchy (h1 once, no skipped levels), not presentational
- **Links**: descriptive text (never "click here" / bare URLs); underlined or 3:1 contrast
- **Images**: descriptive `alt`; decorative `alt=""` or CSS background
- **Forms**: every input has `<label>` (placeholder is NOT a label); `<fieldset>`+`<legend>`
  for groups; error messages perceivable and near the control
- **Contrast**: 4.5:1 body text, 3:1 large text/UI; color never the only differentiator
- **Zoom**: everything usable at 200% without multi-directional scrolling; relative units
- **JS-off**: content usable with JS disabled (`<noscript>` fallbacks for enhanced UI)

## Interaction checklist (JS/CSS)

- All controls keyboard-operable: menus, modals, accordions (focus trap in modals,
  Escape closes, focus returns)
- Focus styles never removed without a more visible replacement
- `prefers-reduced-motion` honored: gate Lenis, GSAP ScrollTrigger anims, marquees,
  auto-playing media (use `gsap.matchMedia` or `window.matchMedia` gate)
- Touch targets ≥ 44×44px
- Icon-only buttons: `aria-label`
- `aria-expanded` + `aria-controls` on toggles; `inert` on closed panels
- No `* { transition: all }`; no animation of non-compositor properties

## Audit procedure

1. Read the markup/template output (or use `chrome-devtools` MCP a11y tree when available)
2. Walk the WCAG 2.2 principles: Perceivable, Operable, Understandable, Robust
3. Report findings: element/selector, principle violated, exact fix
4. WordPress-specific: verify Theme Review a11y minimums (skip link, focus, contrast,
   semantic headings, keyboard nav)

Never claim "accessible" without running the checklist — a passing build proves nothing
about accessibility.
