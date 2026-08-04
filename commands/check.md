---
description: Run the full lint + format + build verification chain and report status.
---

Run the verification chain: npm run build, npm run format:all:check, vendor/bin/phpcs --standard=phpcs.xml -d memory_limit=1024M — in order, stopping at the first red. Report each step's actual result (exit code + first error line). If a script is missing, run the closest equivalent and say what you actually ran. Never report green without running.
