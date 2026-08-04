# Accessibility — WCAG 2.2 AA (WordPress)

Load this when building or reviewing UI. WordPress conformance: WCAG 2.2 Level AA,
WAI-ARIA 1.1. "Accessibility-ready" tag = Theme Review minimums, not a WCAG claim.

## Perceivable

- **Contrast**: 4.5:1 body text, 3:1 large text / UI components; color never the only
  differentiator (links, errors, states)
- **Images**: descriptive `alt` for informative; `alt=""` / CSS background for
  decorative; featured images take alt from media library
- **Zoom**: everything works at 200% without multi-directional scrolling; relative
  font units; `h-dvh` not `h-screen` (dynamic viewport)
- **Repaint on demand**: no autoplaying media without pause; honor
  `prefers-reduced-motion` (gate Lenis, ScrollTrigger, marquees, canvas loops)

## Operable

- **Keyboard**: every control operable (menus, modals, accordions, carousels) at every
  breakpoint; logical tab order = visual order; no focus traps without Escape +
  focus-return
- **Focus**: visible focus styles always (never removed without a more visible
  replacement); skip link first in `wp_body_open()`, visible on keyboard focus
- **Links**: descriptive text, understandable out of context (no bare URLs, no
  repetitive "Read more")
- **Touch**: targets ≥ 44×44px
- **Headings**: logical hierarchy, h1 once, no skipped levels; not presentational

## Understandable

- Forms: every input has a real `<label>` (placeholder is NOT a label); related controls
  in `<fieldset>`/`<legend>`; errors perceivable, near the control, sensible out of
  context; instructions not color/position-dependent
- Consistent navigation across pages; predictable focus movement

## Robust

- Semantic elements: `<button>` for actions, `<a>` for navigation, no `<div onClick>`
- ARIA used correctly: `aria-label` on icon-only buttons, `aria-expanded` +
  `aria-controls` on toggles, `aria-current="page"` on active nav, `inert` on closed
  panels, `role="dialog"` + `aria-modal` on modals
- Content usable with JS disabled (`<noscript>` fallbacks for enhanced UI); valid,
  parsed HTML

## WordPress theme minimums (Theme Review)

Skip link → `wp_body_open()`; semantic landmarks; logical heading hierarchy; descriptive
link text; `alt` on all images; labeled form inputs; visible focus; keyboard-operable
menus; contrast 4.5:1; 200% zoom usability.

## Verification

- Static pass: walk the checklist against the rendered markup
- When available: `chrome-devtools` MCP accessibility snapshot; Lighthouse a11y audit
  (never fake numbers — only report what you ran)
- Keyboard walk: tab through the page, operate every interactive element
