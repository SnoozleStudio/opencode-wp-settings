---
name: wp-github-actions-standards
description: WordPress GitHub Actions Workflow Standards reference — actionlint and zizmor, template injection via env vars, dangerous triggers, least-privilege permissions, persist-credentials false, unpinned uses with SHA pins, cache poisoning. Use when writing or reviewing CI workflows in .github/workflows, or when asked about GitHub Actions security for WordPress projects.
---

# WordPress GitHub Actions Workflow Standards

Distilled from the official WordPress GitHub Actions Workflow Standards
(developer.wordpress.org, Apr 2026). Workflows run in a highly privileged supply
chain environment — a weakness in a workflow file can have severe consequences.

## Goal

Write and review `.github/workflows/*.yml` that pass actionlint (correctness) and
zizmor (security), following WordPress's two-linter discipline.

## When to use

- Writing or reviewing CI workflows in a theme/plugin repo
- Answering "is this workflow safe / standard-compliant"
- Adding actions, triggers, or permissions to an existing workflow

## The standard

### The two linters

- **actionlint** — static checker for correctness: syntax validation, expression
  type-checking, action/reusable-workflow input validation, shell script syntax,
  common mistakes. Run: `actionlint` from the repo root
- **zizmor** — security linter: template injection, excessive permissions,
  dangerous triggers, unpinned dependencies, credential persistence. Run:
  `zizmor .` (note the trailing period); `GH_TOKEN=$(gh auth token) zizmor .` for
  the online audits (known-vulnerable actions, impostor commits)
- A failing actionlint check must be fixed before the change can land

### Security issues to address

**Template injection** — GitHub expressions are interpreted BEFORE the script
runs; attacker-controlled values can inject shell commands even inside quotes.
Never interpolate `${{ github.event.* }}` into a `run:` block or `github-script`
body. Pass through env vars — treated as data, not code:

```yaml
- name: Print title
  run: echo "Title: ${PR_TITLE}"
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
```

**Dangerous triggers** — `pull_request_target` and `workflow_run` run in the base
repo context with secrets access. Avoid unless genuinely needed (commenting on
PRs, managing labels); NEVER check out the PR head ref and run code from it in a
`pull_request_target` workflow; document the justification inline when used.

**Excessive permissions** — least privilege. Every workflow gets a top-level
`permissions: {}` granting nothing, with individual jobs declaring only what they
need. Omitting `permissions` entirely is not sufficient:

```yaml
permissions: {}

jobs:
  lint:
    runs-on: ubuntu-latest
    permissions:
      contents: read
```

**Persisted credentials** — `actions/checkout` persists credentials by default;
if the checkout dir is uploaded as an artifact the credentials leak. Always set
`persist-credentials: false` unless the job must push, then set it explicitly
with a comment.

**Environment manipulation** — writing user-controlled values to `$GITHUB_ENV`
or `$GITHUB_PATH` allows injecting env vars or PATH entries. Only write values
fully controlled by the workflow; validate user input before writing.

**Unpinned uses** — every third-party action pinned to a full commit SHA, never a
tag or branch (tags can move):

```yaml
- uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
```

Always add a version comment matching a REAL ref (check `git ls-remote --tags` —
zizmor fails on comments pointing at nonexistent refs). Update both the SHA and
the comment when bumping.

**Cache poisoning** — avoid `actions/cache`/built-in caching in workflows that
build and publish release artifacts; if unavoidable, scope the key tightly and
verify cache contents.

## Repo-local practice

- This repo's `ci.yml` runs actionlint 1.7.12 + zizmor 1.30.1 in a `workflows`
  job on every push/PR — pinned versions via binary download and `pip`
- Scaffolded theme/plugin templates ship a verification-chain workflow
  (`.github/workflows/ci.yml`) compliant with this standard
- Verified pins: checkout v4.4.0 `11d5960...`, setup-bun v2.2.0 `0c5077e...`,
  setup-php 2.37.2 `f3e473d...` (unprefixed tag — no `v` in the comment)

## Rules

- Never pin an action to a branch or moving tag
- Never interpolate untrusted expressions into `run:` blocks
- Every workflow has `permissions: {}`; every checkout has
  `persist-credentials: false` unless pushing
- Never bypass actionlint/zizmor findings without a documented dismissal

## Output contract

- Written workflows: actionlint-clean and zizmor-clean (verified locally or in CI)
- Review findings: `file:line` + audit type + fix

## References

- [GitHub Actions Workflow Standards — official](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/github-actions/)
- [actionlint docs](https://github.com/rhysd/actionlint) ·
  [zizmor docs](https://docs.zizmor.sh/audits/)
- Internal: [verification chain](../../docs/verification-chain.md) · [hub CI actions table](../../docs/README.md)