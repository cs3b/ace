# TC-002 — Ready: exact head, replay, stale head

Uses the draft PR created in TC-001 (canonical, number recorded there as
`CANON_PR`; its head SHA is `CANON`).

## Goals

### Goal 1 — Ready marks the exact draft ready

1. `bin/ace-git pr ready $CANON_PR --expected-head $CANON --server
   e2e-forgejo --format json` → `ready.json` plus `.exit`.

Expected observations: exits 0, `operation: ready`, `draft: false`, the
title no longer carries the WIP prefix, head unchanged.

### Goal 2 — Ready replay is idempotent

2. Repeat the identical command → `ready-replay.json`.

Expected observations: exits 0, `operation: ready`, `draft: false` (no
mutation; the PR was already ready at the same head).

### Goal 3 — A stale head cannot yield a receipt

3. `bin/ace-git pr ready $CANON_PR --expected-head
   0000000000000000000000000000000000000000 --server e2e-forgejo
   --format json` → `ready-stale.json` plus `.exit`.

Expected observations: exits nonzero with category
`expected_head_conflict`; the PR stays ready and unharmed (record a final
`bin/ace-git pr show $CANON_PR --server e2e-forgejo --format json` →
`show-after-stale.json`).
