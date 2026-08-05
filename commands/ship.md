---
description: Ship it — run the full proof-of-work gate, review, and prepare the commit/PR. Never ships a red build.
---

Ship: $ARGUMENTS

Run the canonical verification chain in order, stopping at the first red
([docs/verification-chain.md](../docs/verification-chain.md)).
Then two-axis review of the diff (review skill). If anything fails, report and fix via the implementer — never commit a failing gate. When green: stage the intended files only, write a conventional commit message (no AI fingerprints), and summarize what will ship.
