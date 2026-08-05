---
description: Run the full lint + format + build + static-analysis verification chain and report status.
---

Run the canonical verification chain in order, stopping at the first red
([docs/verification-chain.md](../docs/verification-chain.md)). Report each step's
actual result (exit code + first error line). If a script is missing, run the closest
equivalent and say what you actually ran. Never report green without running.
