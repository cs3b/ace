---
id: 8wr.t.qk0.1
status: in-progress
priority: high
created_at: "2026-10-07 05:30:22"
estimate: large
dependencies: [8wr.t.qk0.0, 8x3.t.xz9.2, 8wr.t.qjx, 8wr.t.qjy, 8wr.t.qjz, 8wr.t.qk0.3]
tags: []
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/coordinator-source-contract.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/coordinator-admission-draft.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/1-retain-scoped-launchers-through-responsive/cli-selection-and-retry-contract.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/1-retain-scoped-launchers-through-responsive/readiness-review.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/1-retain-scoped-launchers-through-responsive/launch-input-proposal.md, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/1-retain-scoped-launchers-through-responsive/ux/usage.md, ace-overseer/handbook/workflow-instructions/overseer.wf.md, ace-overseer/lib/ace/overseer/cli/commands/work_on.rb, ace-overseer/lib/ace/overseer/organisms/work_on_orchestrator.rb, ace-overseer/lib/ace/overseer/molecules/proposal_tick.rb, ace-overseer/lib/ace/overseer/molecules/assignment_launcher.rb, ace-assign/lib/ace/assign/organisms/task_assignment_creator.rb, .ace-tasks/8wr.t.qk0-coordinate-responsive-overseer-roles-without/3-deliver-authenticated-prepared-work-to/8wr.t.qk0.3-deliver-authenticated-prepared-work-to-scoped-workers.s.md, ace-assign/lib/ace/assign/organisms/assignment_executor.rb, ace-assign/lib/ace/assign/cli/commands/authority/launch.rb, ace-assign/lib/ace/assign/authority/launch_driver.rb, ace-hitl/lib/ace/hitl/proposals/policy.rb]
  commands: []
needs_review: false
parent: 8wr.t.qk0
---

# Retain scoped launchers through responsive role steering

## Program outcome

The Captain can continue issuing instructions while an original protected launcher executes reviewed work, receives attributable steering and completes independent exact-candidate review. This parent is a pure umbrella: all implementation and verification now belong to the following real children.

## Progress checklist

- [x] `8wr.t.qk0.1.0` — original-launcher independent review, actual canonical acceptance and refusal/recovery verification.
- [ ] `8wr.t.qk0.1.1` — responsive prepared launch, retained recovery identity, prompt/stop/status, roles and bounded proposal resolution; consumes qk0.1.0 and qk0.3.

## Completion and ownership

Both children must satisfy their own reviewed source criteria and independent executed-test gates. There is no additional hidden parent implementation. Parent completion cannot imply installed Lab acceptance: deployment/native/runtime proofs remain centralized in lab-config:gad.2.

The full original responsive behavior and SC1–SC3 from commit90d94b043 moved unchanged to qk0.1.1. Shared CLI-selection, launch-input and usage contracts remain here as bundled stable context. Historical design reviews remain in readiness-review.md. Independent structural review approves this transfer; qk0.1.1 depends on sibling .0 plus the prior external prerequisites, never this parent.
