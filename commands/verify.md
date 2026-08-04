---
description: Adversarial verification of code or logic — finder/adversary/referee pattern. Proves the work is correct.
---

Verify: $ARGUMENTS

Use the verify skill: spawn a finder subagent (neutral analysis), then an adversary subagent to disprove each finding, then judge the survivors. Focus on correctness, edge cases, and the WordPress contract (escaping chains, nonce+capability pairing, $wpdb->prepare, cleanup/teardown). Report CONFIRMED/PLAUSIBLE findings with severity, and a go/no-go verdict.
