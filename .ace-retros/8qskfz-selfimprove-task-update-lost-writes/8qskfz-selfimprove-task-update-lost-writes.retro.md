---
id: 8qskfz
title: selfimprove-task-update-lost-writes
type: standard
tags: [self-improvement, process-fix, ace-task, concurrency]
created_at: "2026-03-29 13:37:45"
status: active
---

# selfimprove-task-update-lost-writes

## What Went Well

- The failed parent promotion was noticed immediately because `ace-task show 8qs.t.j24` contradicted the command output.
- The investigation traced the issue to the shared frontmatter updater instead of misattributing it to orchestrator task semantics.
- The repo already had a lock-preserving write example in `ace-assign`, which gave a concrete implementation pattern for the shared fix.

## What Could Be Improved

- `ace-task update` could report success after losing one of two concurrent same-file writes because `FieldUpdater.update` used an unlocked read-modify-write cycle.
- The `task/review` workflow encouraged separate `status` and `needs_review` updates without warning that same-task updates must be serialized.
- The handbook self-improvement workflow itself had a stale `ace-retro create --type self-improvement` example that does not match the current CLI contract.

## Action Items

- Hardened `Ace::Support::Items::Molecules::FieldUpdater` to take an exclusive file lock across the full read-modify-write cycle and rewrite the locked file descriptor in place.
- Added shared regression coverage proving an updater blocks on an existing lock and preserves concurrent frontmatter changes made before the lock is released.
- Added `ace-task update` command coverage for combined scalar updates including `needs_review=false`.
- Updated the `task/review` and `task/update` workflows to prefer one combined `--set` call for same-task scalar changes, forbid parallel same-ref updates, and require immediate `ace-task show` validation.
- Updated the `retro/selfimprove` workflow to use a supported retro create command: `--type standard --tags self-improvement,process-fix`.
- Reuse this incident as the reference case whenever a command reports success but frontmatter state does not match the claimed mutation.
