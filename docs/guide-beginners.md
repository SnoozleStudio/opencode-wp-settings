# Level 1 Guide — AI-Driven WordPress Development (Beginners)

Everything in this repo exists to make one thing true: **you describe what you want in
plain English, and the AI builds production-grade WordPress code that follows the
house rules** — escaping, security, performance, accessibility — and proves it's green
before you commit.

You don't need to know how agents, skills, or plugins work to use this. You need to
know how to ask. This guide teaches you that, with copy-paste-ready prompts.

> Prereqs: OpenCode installed and running in a WordPress project. Read the
> [README](../README.md) first for install. Want the internals instead?
> [Level 2 Guide](guide-pro.md).

---

## Contents

1. [What you're actually talking to](#1-what-youre-actually-talking-to)
2. [How a request becomes work](#2-how-a-request-becomes-work)
3. [The example prompt library](#3-the-example-prompt-library)
   - [Fixing things](#fixing-things)
   - [Building things](#building-things)
   - [Starting a new site](#starting-a-new-site)
   - [Quality checks](#quality-checks)
   - [Shipping](#shipping)
   - [Sessions & planning](#sessions--planning)
4. [How to write prompts that work](#4-how-to-write-prompts-that-work)
5. [When things go wrong](#5-when-things-go-wrong)
6. [Glossary](#6-glossary)
7. [References](#7-references)

---

## 1. What you're actually talking to

Four layers, bottom to top:

| Layer | What it is | In this repo |
|---|---|---|
| **Config** | global settings every session loads | `opencode.json`, `AGENTS.md`, plugins |
| **Agents** | specialist workers the AI can delegate to (a mapper, a coder, a reviewer…) | 8 in `agents/` |
| **Skills** | how-to disciplines the AI loads when a task matches | 26 in `skills/` |
| **Commands** | `/shortcuts` that start a known workflow with a written prompt | 18 in `commands/` |

You almost never touch layers 1–3. You use **commands** and **plain conversation**.
The AI decides which agent/skill to deploy — that's the "AI-driven" part: you don't
say *"spawn the explore subagent"*, you say *"figure out why my menu is broken"*.

Two rules that protect you, always:

- **The verification chain** — before any commit, the AI must run the canonical chain
  (build → format:all:check → phpcs → phpstan, see [verification-chain.md](verification-chain.md)).
  The `proof-of-work` plugin blocks commits when it's red. You never ship broken code
  because the gate physically won't let it through.
- **Stealth mode** — no "generated with AI" fingerprints ever appear in commits.

---

## 2. How a request becomes work

```
You type:  "/fix the mobile menu doesn't open on iPhone"
              │
              ▼
  commands/fix.md  ──►  the fix skill loads: explore → reproduce → diagnose → implement → verify
              │
              ▼
  explore agent maps the menu code (read-only)
  implementer agent fixes it (reads before editing)
  verification chain runs (build + format + phpcs + phpstan)
              │
              ▼
You get: root cause, files changed, verification results
```

Slash commands are just prompts. `/fix …`, `/build …`, `/review` are sentences handed
to the model — the file `commands/fix.md` **is** the sentence. Typing the command by
hand would work; the command guarantees the sentence is well-written and complete.

---

## 3. The example prompt library

Every example below is copy-paste ready. Format: **You say** (the exact prompt) →
**What happens** → **What you get**.

### Fixing things

---

**You say:**

```
/fix the hero animation doesn't play on the front page
```

**What happens:** `/fix` runs the full bug workflow — explore maps the animation code,
the failure is reproduced, the root cause is named in one sentence *before* any edit,
the implementer fixes only the files involved, the verification chain runs.

**What you get:** root cause, the fix, files modified, verification results.

> Pro tip: name the page, the browser, and what "broken" looks like. Paste error
> messages verbatim. Vague ask → vague fix.

---

**You say:**

```
/check is everything green before I commit?
```

**What happens:** the full verification chain runs in order, stopping at the first
red, reporting each step's real exit code. Never reports green without running.

**What you get:** per-step status; if red, the first error line.

---

**You say:**

```
the contact form sometimes doesn't save, only in Chrome, with ACF repeater fields filled
```

**What happens:** matches the `diagnosing-bugs` skill (intermittent, environment-
specific) — reproduce → minimize → hypothesize → instrument → fix → regression-test.
No guessing, evidence before edits.

**What you get:** the named mechanism ("X happens because Y"), the fix, regression
proof.

---

### Building things

---

**You say:**

```
/build a pricing section for the services page, 3 tiers, ACF-driven
```

**What happens:** `/build` checks if the ask is ambiguous (it isn't quite — but scope
still needs data questions: fields? repeater? hover behavior?). It grills you with a
few quick questions, then builds matching the house pattern (PHP + ACF + escaped
output, JS component with cleanup, Tailwind tokens), then verifies.

**What you get:** a working section following every convention, verification results,
and what needs a browser check.

---

**You say:**

```
/section testimonials slider
```

**What happens:** the theme skill's section flow — it first *reads an existing section*
to learn the house pattern, then builds: PHP markup with ACF fields, a JS component
(`src/scripts/components/testimonials.js` — element guard, reduced-motion gate,
cleanup returned), Tailwind tokens. Verification chain runs.

**What you get:** a new section that looks and behaves like the rest of the theme.

---

**You say:**

```
I want a booking form on the home page
```

**What happens:** ambiguous feature → the AI *grills you first* (a handful of focused
questions: what data, which fields, what happens on submit?) before writing anything.
This is deliberate — it prevents building the wrong thing.

**What you get:** an aligned summary (goal, scope, non-goals) and then the build.

---

### Starting a new site

---

**You say:** (from Local's site shell, i.e. right-click your Local site → *Site Shell*)

```
"%USERPROFILE%\.config\opencode\scaffold.cmd" -Theme mytheme -Prefix mt_ -Name "My Theme" -Install
```

**What happens:** `scaffold.cmd` forwards to `setup.ps1`, which detects the WordPress
root (walks up until `wp-load.php`), scaffolds `templates/theme/` into
`wp-content/themes/mytheme/` with slug/prefix/name substituted everywhere, runs
`npm install` + `composer install` (including the workaround for Local's bundled PHP
having openssl disabled), and prints next steps.

**What you get:** a complete enterprise theme skeleton — style.css header, functions.php
boot chain, Vite + Tailwind v4, acf-json, phpcs gate. Then: activate it, sync ACF field
groups, run the verification chain.

> From any directory (no site shell): `& "$HOME\.config\opencode\setup.ps1" -Site mysite -Theme mytheme -Install`
> In OpenCode itself, `/theme mytheme` does the same via the scaffolder agent.

---

**You say:**

```
/plugin testimonials-plugin
```

**What happens:** scaffolder agent copies `templates/plugin/`, substitutes slug/prefix/
namespace/text-domain everywhere, verifies the main-file header and the
`WP_UNINSTALL_PLUGIN` guard in `uninstall.php`, installs deps, and reports the next
commands you must run.

**What you get:** a review-survivable plugin skeleton with the admin/includes/public
split and the WPCS verification chain wired up.

---

### Quality checks

---

**You say:**

```
/review my changes
```

**What happens:** the diff is reviewed on two axes — **Standards** (escaping,
sanitization, nonces, i18n, a11y, conventions) and **Spec** (does it do what you
asked?) — plus a real phpcs run, reported verbatim.

**What you get:** a verdict — APPROVE / APPROVE WITH NITS / REQUEST CHANGES — with
numbered findings at `file:line`, severity, and a concrete fix for each.

---

**You say:**

```
/verify the registration endpoint logic
```

**What happens:** adversarial proof: a *finder* agent analyzes for bugs, an
*adversary* agent tries to disprove each finding, and the referee judges the
survivors. False positives get killed by the adversary — you only see findings that
survive attack.

**What you get:** a CONFIRMED/PLAUSIBLE findings table and a go/no-go verdict.

---

**You say:**

```
is my plugin secure? audit it
```

**What happens:** the security-auditor agent reviews the full WordPress attack
surface — escaping matrix, SQL injection, CSRF/nonces, capabilities, REST exposure,
secrets — proving each finding by tracing the data flow with `file:line` and a
severity. Never fabricated.

**What you get:** numbered findings (critical → low), failure scenario per finding,
and the concrete fix for each.

---

**You say:**

```
/phpcs src/scripts -- wait, it's PHP: /phpcs includes/  or just /phpcs
```

**What happens:** runs phpcs against the project's `phpcs.xml`, findings grouped by
file, most severe first, classified by kind (escaping / sanitization / i18n /
convention / docs). If the project's phpcs.xml is weak, that's reported as a finding
too.

**What you get:** a lint report and clear classification of each violation.

---

**You say:**

```
/refactor the checkout module
```

**What happens:** the refactor skill explores the module and its callers, states the
target shape, then moves in small behavior-preserving steps — verification chain
after every step. If a step changes behavior, it stops and flags it instead of
covering it up.

**What you get:** what moved, what stayed, and anything flagged for later. Behavior
is identical before and after.

---

**You say:**

```
my site is slow, /audit performance
```

**What happens:** a whole-codebase audit: pass 1 structure & dead code (explore
agent), pass 2 security (security-auditor), pass 3 docs drift. Performance findings
(autoloaded options, enqueue bloat, bundle size) are reported as measured findings —
never invented numbers.

**What you get:** a numbered findings report with `file:line`, severity, and concrete
fixes. Read-only: nothing gets edited without your say-so.

---

### Shipping

---

**You say:**

```
/ship
```

**What happens:** the full gate, in order, stopping at the first red — the canonical
verification chain ([verification-chain.md](verification-chain.md)). Then a
two-axis review of the diff. Then (only
when everything is green) staging the intended files and a conventional commit —
no AI fingerprints.

**What you get:** a clean commit, with a summary of exactly what will ship. If
anything is red, it stops and tells you — it never ships a red build.

---

### Sessions & planning

---

**You say:**

```
/grill I want to add a careers section to the theme
```

**What happens:** an alignment session — the AI interviews you one question at a time
until every branch is resolved (scope, ACF fields, behavior, edge cases, non-goals),
then states the aligned summary before any work begins.

**What you get:** a crystal-clear scope, zero rework from misalignment.

---

**You say:**

```
/spec what we just discussed about the booking form
```

**What happens:** the conversation is synthesized into a written spec — goal, scope,
behavior with checkable acceptance criteria, the WordPress contract (templates, ACF
fields, hooks, i18n), verification steps, risks. Under ~120 lines.

**What you get:** a spec file that becomes the contract for implementation and review.

---

**You say:**

```
/tickets the booking form spec
```

**What happens:** the spec is broken into small tracer-bullet tickets with declared
blocking edges (what must land first), files each may touch, and checkable acceptance.
Tickets that share files are serialized automatically.

**What you get:** a ticket file with an execution order — what first, what can run in
parallel.

---

**You say:**

```
I'm done for today, /handoff
```

**What happens:** a one-page handoff is written: goal, state, files touched, decisions,
next steps (each with the verification it must pass), open questions, and pre-
continuation commands. A fresh session can resume without making you re-explain.

**What you get:** continuity. Close the laptop; tomorrow's session picks up the thread.

---

### Disciplines the AI invokes on its own

No slash needed — these skills auto-match from plain-language requests:

| You say | Skill that fires |
|---|---|
| "research the current best practice for X against official docs" | `research` — cited answers, no guessing |
| "record this gotcha in the learnings log" | `share-learning` — one dated line in AGENTS.md |
| "write this test-first, red-green-refactor" | `tdd` |
| "audit this form for accessibility (WCAG 2.2 AA)" | `wp-accessibility` |
| "make these strings translation-ready" | `wp-i18n` — text domain, escaping matrix |
| "profile the front page — web vitals, bundle size" | `wp-performance` |

---

## 4. How to write prompts that work

The same request, two ways:

| Weak prompt | Strong prompt |
|---|---|
| "fix the menu" | `/fix the mobile menu doesn't open on iPhone 14, only Safari — sticky header, Lenis enabled` |
| "add a section" | `/section pricing, 3 tiers, ACF repeater with title+price+features, matching the services section style` |
| "check my code" | `/review` (after staging changes) |
| "clean up a module" | `/refactor` — behavior-preserving steps, chain after every step |
| "make it faster" | `/audit` — then point at the page: "front page, biggest CLS offender" |
| "I need a form" | "I want a booking form on the home page" (the AI will grill you) |
| "what does this codebase do?" | `/context` — builds the project glossary and ADR log |

Rules of thumb:

1. **Name the thing** — page, component, file, browser, device. "The hero" beats "it".
2. **Say what done looks like** — "3 tiers, hover to expand, ACF-driven" is a spec in
   a sentence.
3. **Paste errors verbatim** — screenshots of text help nothing; the error string
   helps everything.
4. **Use slash commands for known workflows** — `/fix`, `/build`, `/review`, `/ship`,
   `/context` are written by engineers who encoded the process. Plain conversation
   for questions ("what does this function do?").
5. **Say "you decide" when you trust it** — grilling respects that and stops asking.

---

## 5. When things go wrong

The system is built to fail honestly, and to stop early:

| Situation | What happens | What you do |
|---|---|---|
| Fix attempt fails twice | the **2-iteration limit** stops the work | you get 2-3 alternative approaches with trade-offs — pick one |
| A check is red | the gate refuses to commit | read the first error, ask `/check` again after fixes — never bypass with `--no-verify` unless you know exactly why |
| Visual/animation work | the AI says "compiles green, needs browser validation" | check it in the browser — that's expected, not a failure |
| Context feels lost / long session | `/handoff` (checkpoint) | quicksave, continue later |
| A tool can't run (no network, missing binary) | the AI says so explicitly | never pretend a check passed — the honesty rule |

The most important behavior: **if the AI stops and asks you a question, it's not
stuck — it's applying the stop-and-replan rule.** Answer it.

---

## 6. Glossary

| Term | Meaning |
|---|---|
| **Agent** | a specialist worker the AI can delegate to (explore = maps code, implementer = writes code, reviewer = reviews diffs, …) |
| **Skill** | a how-to discipline the AI loads on demand; matched by its description |
| **Command** | a `/shortcut` — a well-written prompt for a known workflow |
| **Plugin** | code that hooks into OpenCode itself (commit gate, lint watcher, status line) |
| **Verification chain** | the canonical proof-of-work chain — build → format:all:check → phpcs → phpstan, see [verification-chain.md](verification-chain.md) |
| **phpcs** | PHP_CodeSniffer — the PHP lint gate against the WordPress Coding Standards |
| **PHPStan** | static analysis of PHP types (level 8) — catches type bugs phpcs can't see |
| **ACF** | Advanced Custom Fields Pro — where content fields live (`get_field()`) |
| **ACF-json** | the sync files for field groups (edit once, ship everywhere) |
| **Grilling** | the alignment interview before ambiguous work |
| **Handoff** | one-page session transfer so a fresh session can continue |
| **Stealth mode** | no AI fingerprints in git history, ever |
| **WPCS** | WordPress Coding Standards (the rules phpcs enforces) |

---

## 7. References

- [OpenCode docs](https://opencode.ai/docs) — the tool itself (agents, skills, commands, plugins)
- [Level 2 Guide](guide-pro.md) — how it all works under the hood
- [Level 3 Guide](guide-advanced.md) — tuning agents, skills, and plugins
- [Documentation hub](README.md) — every component indexed
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/php/) — what phpcs enforces
- [WordPress Plugin Handbook](https://developer.wordpress.org/plugins/) — plugin contract
- [WordPress Theme Handbook](https://developer.wordpress.org/themes/) — theme contract
