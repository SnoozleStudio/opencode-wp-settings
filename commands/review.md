---
description: Review the current diff on two axes (standards + spec) before commit or PR.
---

Review the diff ($ARGUMENTS) using the review skill. Determine the diff (git diff / git diff HEAD / branch range), then review on two axes: Standards (repo conventions, WordPress escaping/sanitization/SQLi/CSRF/capabilities, a11y, JS cleanup patterns) and Spec (faithful implementation of the ask). Run phpcs and report its findings verbatim. Verdict: APPROVE / APPROVE WITH NITS / REQUEST CHANGES with numbered findings (file:line, severity, fix).
