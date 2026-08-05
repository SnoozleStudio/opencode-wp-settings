---
name: verify
description: Adversarial verification that code, logic, or a completed task is CORRECT. Use for "double check this logic", "prove it", "is this bug really fixed". Three-agent pattern: finder finds issues, adversary tries to disprove them, referee judges. For high-stakes correctness. Not for standards/spec review (use review) or attack-surface security (use wp-security-audit).
---

# Adversarial Verification

Prove the work is right — not by re-reading it fondly, but by attacking it.

## Pattern

1. **Finder** (subagent): analyze the target (diff, function, flow) for correctness bugs,
   edge cases, incoherences. Neutral prompt — "analyze and report all findings"
2. **Adversary** (subagent): take each finding and try to disprove it. A finding that
   survives the adversary is real; one that doesn't is dropped. This kills false
   positives without argument
3. **Referee** (you): judge the survivors. Classify each as confirmed/plausible with
   severity. Confirmed blockers stop the work; plausible findings get verified by
   reading code or running the path

## What to verify

- Logic correctness (off-by-one, empty states, error paths)
- WordPress contract: escaping chain on every output, nonce + capability pairing,
  `$wpdb->prepare`, hook timing
- Data flow: input → sanitize → validate → store → escape → output, end to end
- Cleanup: every initialized lib can be torn down (Lenis destroy, context revert,
  Tempus unsubscribe, Three dispose)

## Rules

- Never verify by rerunning the same check that failed — change the angle
- Never fake measurements: if verification requires a tool you can't run, say so
- Two agents agreeing on a false positive is not a mandate — the referee decides with
  evidence

## Output

Findings table (status CONFIRMED/PLAUSIBLE, severity, file:line, failure scenario),
verdict per item, and a final go/no-go.
