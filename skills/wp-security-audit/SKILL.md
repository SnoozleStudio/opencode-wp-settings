---
name: wp-security-audit
description: Run a WordPress-specific security review of a plugin, theme, or code change. Use when auditing code for XSS, SQL injection, CSRF, privilege escalation, REST exposure, secret leaks, or before shipping security-sensitive changes. Produces proven findings with file:line, severity, and fixes — never fabricated.
---

# WordPress Security Audit

Delegates to the `security-auditor` agent. Load `docs/wordpress-security.md` first — it is
the doctrine; this skill is the procedure.

## When to run

- Before committing anything that touches input, output, or authorization
- As a full audit pass before releases
- When a bug report smells like a security issue
- After any REST endpoint or AJAX handler is written

## Procedure

1. Load `docs/wordpress-security.md`
2. Spawn `security-auditor` with scope: files (diff list or paths) + the threat model
   (public-facing? admin? logged-in users? what data?)
3. Triage findings: every finding must be CONFIRMED (data flow traced, `file:line` named,
   missing control identified) or explicitly PLAUSIBLE — no vibes
4. For each confirmed finding, fix with the implementer under the escaping/sanitization
   matrix — never "fix" by weakening the finding
5. Re-run the verification chain after fixes
6. Report: findings table, what was fixed, what remains, and any secrets found

## Severity guide

| Severity | Example |
|---|---|
| Critical | SQLi with `$wpdb` interpolation; unauthenticated data exposure |
| High | Stored XSS via unescaped output; CSRF on state change; missing capability on admin AJAX |
| Medium | Escaped-at-store pattern; autoload bloat; missing `wp_unslash` |
| Low | Nonces without IDs in action strings; debug code left in |

## Anti-patterns to check (always)

- `esc_attr( $url )` instead of `esc_url()`
- `echo $_GET[...]` without sanitize+escape chain
- `$wpdb->query( "SELECT ... $var ..." )`
- `is_admin()` used as an auth check
- REST route with no `permission_callback`
- `update_option` on every request instead of autoload:false + transients
- API keys hardcoded or in options/i18n strings

## Verification chain

```
npm run build
npm run format:all:check
vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
vendor/bin/phpstan analyse --no-progress --memory-limit=1G
```

Secrets additionally: `git log -p --all` grep for key material, `.env*` in repo.
