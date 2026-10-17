# Retrospective — L1.2 simplify old lab execution paths

## What went well

- The two-phase split worked: a code worker removed the protected ace-lab /
  ace-overseer surface while a flow worker de-required the same model from
  presets, workflows, canonical skills and cross-package tests. The load-time
  breakages were fixed together, so `ace-lab`, `ace-overseer` and `ace-hitl`
  suites stayed green.
- Obsolete needs were deleted rather than shimmed: four delivery/queue presets,
  five coordinator/role workflows, protected-only tests and the protected e2e
  scenario are gone (about 14.5k lines in the flow commit and 12.7k in the code
  commit).
- Needed operations were explicitly retained and covered: ordinary fixed merge,
  topology, run kernel, release publication, Forgejo adapter, HITL/grant
  authorizers and transports.
- The `prepared_input` rewrite kept local attempt evidence instead of inventing a
  replacement authority.

## What could improve

- The ace-assign `feat` suite contains socket-heavy tests that take minutes and
  hang under host load (also on unmodified main). The L1 verification had to
  rely on the fast suite plus per-file evidence for three ordinary files. The
  suite should get a load-independent timeout harness in a follow-up.
- Deleting protected tests while keeping the installed ordinary authority code
  leaves a residual code surface; it is scoped to L3/L6 but should be removed or
  re-homed there rather than left indefinitely.
- A generated `.pi/` provider projection appeared during `ace-handbook sync` and
  had to be removed from the worktree; provider projections should be ignored or
  explicitly scoped.

## Action items

- L3/L6: remove or re-home the remaining protected authority implementation in
  ace-assign and add deterministic (non-socket-heavy) coverage for the ordinary
  path.
- Add a CI/runtime guard for socket-heavy tests (bounded timeouts) so host load
  cannot mask regressions.
- Add generated provider projection directories to ignore rules or a sync flag.
