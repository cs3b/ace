---
id: 8vb.t.vy9
status: draft
priority: high
created_at: "2026-08-12 21:18:05"
estimate: TBD
dependencies: []
tags: [lifecycle, recommendations, delivery, orchestrator]
github_issue: 311
bundle:
  presets: [project]
  files: [ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb, ace-support-config/lib/ace/support/config/cli.rb, ace-git-worktree/.ace-defaults/git/worktree.yml, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-task/handbook/skills/as-task-work/SKILL.md, ace-task/handbook/workflow-instructions/task/work.wf.md, ace-review/.ace-defaults/review/config.yml, ace-handbook/.ace-defaults/handbook/providers/agents.yml, ace-support-core/.ace-defaults/project-root/AGENTS.md]
  commands: [ace-config doctor --no-probe --json, ace-bundle wfi://task/work, ace-bundle wfi://assign/drive, ace-handbook status]
---

# Safe application lifecycle recommendations and delivery defaults

## Behavioral Specification

### User Experience

- **Input:** A developer selects a project recommendation profile or invokes the public task-work skill for a task outcome.
- **Process:** ACE reports versioned lifecycle drift, applies conservative package defaults, and drives an explicit delivery outcome with review and evidence gates.
- **Output:** Minimal projects remain quiet, application projects receive actionable findings and safe delivery behavior, and ACE development retains its broader workflow through an explicit preset.

### Expected Behavior

ACE exposes a coherent lifecycle contract across configuration health, worktree creation, assignment routing, implementation ownership, review execution, final evidence, and guarded merge. The parent owns the umbrella outcome; every independently verifiable capability is specified in a child task.

Focused worktree cleanup (#312), bootstrap readiness (#313), and the explicitly enabled bookkeeping-commit safety fix (#314) remain separate tasks.

### Interface Contract

```bash
ace-config doctor --recommendations [--profile minimal|application|ace-development] [--json] [--strict] [--check-updates]
/as-task-work <task-ref> [--preset work-on-task|work-on-task-auto-merge|work-on-task-in-place|work-on-task-ace-development]
```

Error Handling:

- Unsupported profiles fail with the accepted values and do not run partial checks.
- Recommendation findings do not change the normal exit status unless `--strict` is supplied.
- Delivery cannot report a terminal outcome when review, verification, exact-head evidence, or guarded authorization is missing or stale.

Edge Cases:

- With no CLI or project profile, recommendations use `minimal`.
- Only an explicit update check may use the network.
- Project-owned workflow and guidance overrides remain authoritative and are assessed without being rewritten.

## Success Criteria

- All six child slices satisfy their behavioral and verification contracts.
- Minimal, application, and ACE-development profiles produce profile-appropriate results without unrelated package warnings.
- Public task work has one unambiguous entrypoint and cannot bypass delivery through metadata-aware or metadata-blind routing.
- Application delivery stops at the selected terminal outcome with current, exact-head evidence.
- Linked GitHub issue #311 receives this task reference through `ace-task github-sync`.

## Validation Questions

- None open. Approved defaults: `minimal` fallback, explicit network update checks, checkout-only worktree defaults, and digest-bound guarded merge.

## Vertical Slice Decomposition Task/Subtask Model

| Slice | Ref | Observable outcome | Size |
|-------|-----|--------------------|------|
| Orchestrator | `8vb.t.vy9` | Profile-aware health and safe task delivery operate as one lifecycle | large |
| Subtask | `8vb.t.vy9.0` | Doctor reports stable profile-aware findings | medium |
| Subtask | `8vb.t.vy9.1` | Installed workflow policy violations are detected | large |
| Subtask | `8vb.t.vy9.2` | Package-owned application defaults are conservative | large |
| Subtask | `8vb.t.vy9.3` | Public task work reaches explicit outcome presets | large |
| Subtask | `8vb.t.vy9.4` | Final review and merge evidence is exact-head bound | large |
| Subtask | `8vb.t.vy9.5` | Exceptions expire and update checks stay explicit | medium |

## Verification Plan

### Unit/Component Validation

- Covered by each child task's owner-package checks.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Fixtures cover all profiles, all task outcomes, cross-agent routing, worktree-aware continuation, and exact-head invalidation.

### Failure/Invalid Path Validation

- Invalid profiles, missing review reports, stale receipts, and risky auto-merge states fail closed without workflow mutation or merge.

### Verification Commands

- `ace-task show 8vb.t.vy9`
- Child-specific `ace-test` and `ace-test-suite` commands recorded in each child.

## Objective

Give long-running projects a versioned health screen and make ordinary application delivery safe, sequential, evidence-bound, and distinct from ACE's package-release workflow.

## Scope of Work

- Profile-aware lifecycle recommendations and reviewed exceptions
- Conservative application defaults across the owning ACE packages
- Public/internal task-work routing and four outcome presets
- Exact-head review, release, and guarded merge evidence

## Deliverables

### Behavioral Specifications

- This orchestrator contract and six real child task specifications
- Draft usage scenarios in `ux-usage.md`

### Validation Artifacts

- Profile, routing, terminal-state, continuation, changelog, receipt, and downgrade scenarios

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Versioned recommendation profiles and findings | `8vb.t.vy9.0` | — | KEPT |
| Semantic workflow policy checks | `8vb.t.vy9.1` | — | KEPT |
| Conservative application package defaults | `8vb.t.vy9.2` | — | KEPT |
| Outcome-based public task delivery | `8vb.t.vy9.3` | — | KEPT |
| Exact-head receipts and guarded merge digest | `8vb.t.vy9.4` | — | KEPT |
| Expiring acknowledgements and explicit updates | `8vb.t.vy9.5` | — | KEPT |

## Out of Scope

- Implementing the cleanup, bootstrap, or scoped bookkeeping behavior owned by issues #312–#314
- Automatically rewriting customized project workflows or guidance
- Requiring release, demo, retro, fork, tmux, or multiple providers for ordinary applications
- Package code implementation during this draft phase

## References

- https://github.com/cs3b/ace/issues/311
- https://github.com/cs3b/ace/issues/311#issuecomment-5272561943
- https://github.com/cs3b/ace/issues/311#issuecomment-5272600761
- `ux-usage.md`
