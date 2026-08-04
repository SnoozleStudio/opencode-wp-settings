---
name: grill-me
description: Alignment session — interview the user relentlessly about a plan, feature, or idea until every branch of the decision tree is resolved. Use before starting ambiguous work ("I want a booking form", "add a careers section", "make the site faster"). Prevents building the wrong thing.
---

# Grill-Me — Alignment Before Work

The most common failure mode in AI-assisted development is misalignment: you think the
agent understood, then it built the wrong thing. The fix is a grilling session — detailed
questions BEFORE code.

## How to run

1. State your understanding of the request in one sentence. If the user refines it, adopt
   their language
2. Interview until every branch is resolved. Ask one question at a time, concrete, in the
   user's domain language. Branches to cover for WordPress work:
   - **Scope**: what page/template/section exactly? Is it ACF-driven (which fields) or
     hardcoded? Both?
   - **Data**: where does content come from (post types, options pages, repeaters)?
   - **Behavior**: interactions (accordion, hover, scroll-triggered?), required on
     mobile/reduced-motion?
   - **Design constraints**: house patterns (grid, tokens), existing components to match
   - **Edge cases**: empty states, no-JS, slow devices, logged-out vs logged-in
   - **Non-goals**: what is explicitly out of scope?
3. Question limits: stop when answers are predictable or the user says "you decide" —
   respect the user's time; ~6-12 questions is typical for a section, fewer for a bug
4. When the grilling is done, state the aligned summary (goal, scope, non-goals,
   verification) and begin

## Rules

- Never start implementation on an ambiguous ask — grilling is mandatory for
  features/sections; skip it only for bug reports (fix immediately) and trivial asks
- Never grill for grilling's sake — questions must be decision-relevant
- Record the aligned summary in the session so implementation doesn't drift
- If the user wants speed over completeness, honor that — grilling scales down to 2-3
  questions for a one-file change
