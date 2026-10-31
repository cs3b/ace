---
id: 8xu.t.azx
status: in-progress
priority: high
created_at: "2026-10-31 07:19:56"
estimate: 
dependencies: []
tags: []
---

# Lab bootstrap: delegated worker and observed completion

## Accepted brief

Deliver one real lab cycle: the lab overseer commissions ACE bootstrap, a
separate worker prepares it, an independent verifier accepts it, and semantic
observation wakes the overseer to confirm the project's first turn and eyes.
The overseer does not install, configure or repair the project itself.

## Acceptance

- [ ] All six Omarchy commits are preserved and integrated without duplication.
- [ ] Explicit installed mode survives project start and worker delegation.
- [ ] Lab bootstrap is task-backed delegated work, including when the project overseer is unavailable.
- [ ] Eyes can be armed by the agent and proves readiness before dispatch.
- [ ] Worker completion, independent verification and project startup are distinct accepted steps.
- [ ] Duplicate reports and restart do not duplicate executors or effects.
- [ ] Five unchanged live minutes produce no additional model turn.
- [ ] A published, installed candidate passes the actual lab cycle with linked evidence.

## Constraints

Use existing task/assignment/HITL/eyes owners. No queue engine or second state
store. No tracked-binstub workaround. No Second Captain expansion. Keep this
family in-progress until live acceptance, regardless of unit test results.
