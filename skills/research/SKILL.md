---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a cited Markdown file in the repo. Use for "how does WordPress handle X", "what's the current best practice for Y", "compare approaches" — anything requiring current documentation. Runs as a background agent; always uses Context7 or official docs, never guesses API knowledge.
---

# Research — Evidence Over Memory

Library APIs change; WordPress moves; your training data ages. When the answer matters,
research it — with citations.

## Procedure

1. **Source hierarchy** (high-trust first):
   - Context7 MCP (library/framework docs, current)
   - Official docs: developer.wordpress.org, the library's own docs site
   - Primary source code (WordPress core `wp-includes/`, the library's repo)
   - Community/vendor blogs only as a tiebreaker, cited as such
2. Run as a background agent when the question is deep — don't block the session
3. **Verify versions**: which WP version / library version do the findings apply to?
   Note it in the output (e.g. "Vite 8 uses `rolldownOptions`; `build.rollupOptions` is a
   deprecated alias")
4. Capture findings as a cited Markdown file: `docs/research/{slug}.md` with:
   - The question, answered in 2-3 sentences
   - Key findings, each with its source URL and the version it applies to
   - "Not proven" section for anything you couldn't verify — unknown stays unknown,
     never aspirational

## Rules

- Never answer from memory when the answer is load-bearing (API signatures, hook timing,
  config options) — fetch first
- Distinguish quoted docs from your synthesis; the file must be audit-able
- Before implementing with any external library, this skill (or the context7 MCP prompt
  itself) is mandatory per the External Libraries rule in AGENTS.md
- Never fabricate a citation — a URL you didn't fetch is a lie
