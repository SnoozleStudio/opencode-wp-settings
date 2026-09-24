---
name: wp-accessibility-standards
description: WordPress Accessibility Coding Standards reference — WCAG 2.2 conformance levels A and AA, the four principles, success criteria, sufficient and advisory techniques, normative documents, authoritative resources. Use when asked about WordPress accessibility conformance, WCAG levels, or accessibility standards and references. For hands-on enforcement checklists use the wp-accessibility skill.
---

# WordPress Accessibility Coding Standards

Distilled from the official WordPress Accessibility Coding Standards
(developer.wordpress.org). Code integrated into the WordPress ecosystem is expected
to conform to WCAG 2.2 at Level AA; ATAG 2.0 is encouraged for authoring tools.
Level AAA conformance is encouraged where relevant.

## Goal

Know what the WordPress accessibility conformance commitment actually is — the
levels, principles, criteria, and the authoritative documents — and route hands-on
enforcement to the `wp-accessibility` skill.

## When to use

- Answering "what does the WordPress accessibility standard require"
- Questions about WCAG conformance levels (A/AA/AAA), principles, or techniques
- Choosing authoritative references for an accessibility audit

## The standard

### Conformance levels

- **Level A** — barriers on a very wide scale; the minimum for most web interfaces
- **Level AA** — common needs with broad reach; WordPress's commitment level
- **Level AAA** — very specific needs, often difficult to implement; encouraged
  where relevant

### The four principles (POUR)

1. **Perceivable** — text alternatives (1.1), time-based media (1.2), adaptable
   content (1.3), distinguishable presentation (1.4)
2. **Operable** — keyboard access (2.1), enough time (2.2), no seizures/physical
   reactions (2.3), navigable (2.4), input modalities (2.5)
3. **Understandable** — readable text (3.1), predictable behavior (3.2), input
   assistance (3.3)
4. **Robust** — compatible with current and future user agents incl. assistive
   tech (4.1)

### Success criteria and techniques

- Each guideline has testable success criteria — automated and human testing
- Techniques are Sufficient (required to meet criteria), Advisory (beyond
  requirements), or Failures (cause criteria to fail)
- Usability testing runs alongside accessibility testing — criteria alone are
  not enough

### Normative documents

- W3C WCAG 2.2 (the requirements) · W3C ATAG 2.0 (authoring tools) ·
  W3C WAI-ARIA 1.1 (ARIA spec)

### Informative documents

- Understanding WCAG 2.2 · Using ARIA · WAI-ARIA Authoring Practices Guide
  (design patterns) · Introduction to ATAG

### Authoritative resources

WebAIM, UK Government Digital Service, Section 508, TPGi, Deque, W3C APG — plus
the community references listed on the official page (Roselli, O'Hara, Dolson,
Inclusive Components, etc.)

## Relationship to wp-accessibility

- **This skill** — conformance, levels, principles, references (the standard)
- **`wp-accessibility` skill** + `docs/accessibility.md` — the enforcement
  checklist: contrast 4.5:1, keyboard operability, focus, aria, labels, reduced
  motion, Theme Review minimums

## Rules

- WCAG 2.2 AA is the commitment — never claim AAA conformance without evidence
- Cite normative docs when challenged; don't guess criteria numbers
- Never fake audit results — only report what was actually run

## Output contract

- Standards questions: answer with the level, principle, and normative source
- Audits: hand off to `wp-accessibility` for the enforcement checklist

## References

- [Accessibility Coding Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/accessibility/)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/) · [ATAG 2.0](https://www.w3.org/TR/ATAG20/) ·
  [WAI-ARIA 1.1](https://www.w3.org/TR/wai-aria-1.1/)
- Internal: [accessibility enforcement](../../docs/accessibility.md) · [wp-accessibility](../wp-accessibility/SKILL.md)