---
description: Ship it — run the full proof-of-work gate, review, and prepare the commit/PR. Never ships a red build.
---

Ship: $ARGUMENTS

Run the full gate in order, stopping at the first red:
1. npm run build
2. npm run format:all:check
3. vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M
4. vendor/bin/phpstan analyse --no-progress --memory-limit=1G
Then two-axis review of the diff (review skill). If anything fails, report and fix via the implementer — never commit a failing gate. When green: stage the intended files only, write a conventional commit message (no AI fingerprints), and summarize what will ship.
