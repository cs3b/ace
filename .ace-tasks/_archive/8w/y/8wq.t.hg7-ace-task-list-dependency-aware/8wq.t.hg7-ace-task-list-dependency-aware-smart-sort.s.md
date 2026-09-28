---
id: 8wq.t.hg7
status: done
priority: medium
created_at: "2026-09-27 11:38:01"
estimate: 
dependencies: []
tags: [ace-task, list, sort, dependencies]
---

# ace-task list: dependency-aware smart sort (ready-first, topological)

## Kontekst

`ace-task list` default `--sort=smart` orders by priority + `position`
(B36TS creation stamp). Position reflects when a task was created — for a
bulk-recreated backlog, creation order ≠ work order — so dependent tasks
can list above the tasks they depend on (observed 2026-09-27: `8wq.t.1w0`
listed before its dependency `8wm.t.vs0`). No existing sort option
(`id`/`priority`/`created`) considers dependencies.

Manual mitigation used meanwhile: `ace-task update <ref> --position
first|after:<ref>|before:<ref>` to encode work order by hand (applied to
the 2026-09-27 open set). That ordering goes stale as tasks complete.

## Scope

Make the `smart` sort dependency-aware in `ace-task list` (root/next view):

1. **Ready first**: tasks whose `dependencies` are all satisfied (done or
   archived) sort before tasks with unmet dependencies, priority within
   each group as today.
2. **Topological tail**: among tasks with unmet deps, order by dependency
   depth (fewest hops to ready first); deterministic tie-break on existing
   position/id ordering.
3. Cycles render at the tail with a marker instead of being hidden or
   looping.
4. Keep `--sort=id|priority|created` unchanged (dumb, literal sorts).

## Akceptacja

- [x] With `A→B` (B depends on A, A pending), list shows A before B
      regardless of creation order.
- [x] Done dependencies do not demote a task (dep satisfied = ready).
- [x] Deterministic output across runs (no map-order leakage).
- [x] Existing tests updated; `bundle exec ace-test ace-task all` green.
- [x] CHANGELOG entry under `[Unreleased]`.
