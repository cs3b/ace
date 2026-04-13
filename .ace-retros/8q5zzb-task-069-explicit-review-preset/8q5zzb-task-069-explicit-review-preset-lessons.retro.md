---
id: 8q5zzb
title: task-069-explicit-review-preset-lessons
type: standard
tags: [ace-review, ace-llm, task-069, architecture]
created_at: "2026-03-06 23:59:15"
status: active
task_ref: 8c0.t.069
---

# task-069-explicit-review-preset-lessons

## What Went Well

- Re-centering `ace-review` on explicit preset files made the runtime and config model much easier to understand than the weighted reviewer/pipeline direction.
- Moving effort and reasoning controls into `ace-llm` produced a cleaner separation of concerns and a more stable mental model.
- Targeted smoke checks (`--list-presets`, `--dry-run`) exposed real runtime issues quickly without requiring broad exploratory work.
- Package-scoped releases still worked well for `ace-llm` and `ace-review` once the release surface was narrowed to the intended files.

## What Could Be Improved

- The original task spec overfit an architecture before validating whether the added orchestration actually created product value.
- Config-cascade behavior was under-specified; `.ace/review` overrides drifted away from package defaults and hid the true runtime surface.
- Release/commit workflows made it easy to miss repo-level `.ace` behavior changes because those files were outside the package-scoped release commits.
- `--dry-run` semantics were not guarded strongly enough against `auto_execute` defaults.

## Key Learnings

- The highest-value unit in `ace-review` is an explicit, self-contained preset file, not a reviewer pipeline.
- Provider runtime knobs belong in `ace-llm`; `ace-review` should express intent, not provider-specific execution policy.
- If a config cascade exists, every layer of that cascade is part of the real product and must be treated as such in specs and reviews.
- Optional reviewer lanes may still be useful, but only as an explicit secondary extension owned by the preset itself.
- Future specs should define the simplest architecture that delivers the user-facing value first, then describe advanced extensions separately.

## Action Items

### Stop Doing

- Stop treating reviewer metadata orchestration as the default design before proving it is the best value path.
- Stop assuming package defaults alone define runtime behavior when repo-level `.ace` overrides exist.

### Continue Doing

- Continue validating architectural simplifications against real runtime behavior rather than only code structure.
- Continue using narrow smoke checks to confirm config and execution semantics before assuming a rewrite is complete.

### Start Doing

- Start writing task specs that separate the baseline architecture from optional advanced extensions.
- Start treating `.ace` repo overrides as first-class review/release scope whenever they change runtime behavior.
- Start capturing architecture pivots as retros earlier so future tasks inherit the right lessons.

## Technical Details

- `ace-review` now proves that package defaults and repo-level overrides must remain aligned for preset discovery to be trustworthy.
- `ace-llm` now carries explicit thinking-level parsing and provider-side overlay loading, which is the correct long-term seam for future expansion.
- `--dry-run` must dominate execution defaults; otherwise the CLI contract becomes misleading even when the rest of the architecture is correct.

## Automation Insights

### Identified Opportunities

- **Runtime surface diffing**: compare package defaults and repo-level `.ace` overrides for the same tool.
  - Current approach: discovered manually through smoke checks after implementation.
  - Automation proposal: add a tool or validation command that reports contract drift between package defaults and active project overrides.
  - Expected time savings: medium.
  - Implementation complexity: medium.

- **Release scope validation**: warn when package-scoped release commits leave related repo-level config changes uncommitted.
  - Current approach: discovered by checking `git status` before push/PR creation.
  - Automation proposal: teach release/commit workflows to surface related `.ace` files when they affect the same package runtime.
  - Expected time savings: medium.
  - Implementation complexity: medium.

### Priority Automations

1. **Config cascade drift check**: detect package-default vs `.ace` override divergence for runtime-facing presets and configs.
2. **Release scope hinting**: warn when package-scoped commits exclude nearby repo-level runtime files.
3. **Dry-run contract checks**: add a lightweight assertion path for commands where dry-run must suppress execution.

## Workflow Proposals

### Workflow Enhancements

- **Existing Workflow**: `release`
  - Enhancement: surface related `.ace` runtime files when releasing a package whose behavior also depends on repo-level overrides.
  - Rationale: package-only releases can miss real runtime changes.
  - Impact: fewer incomplete release commits.

- **Existing Workflow**: `task draft/review`
  - Enhancement: explicitly ask whether a proposed architecture is baseline or optional extension.
  - Rationale: would have exposed the over-built reviewer-pipeline direction earlier.
  - Impact: simpler, more resilient task specs.

## Additional Context

- Source worktree: `/home/mc/ace-improve-review`
- Related task: `8c0.t.069`
- Related PR: `#237`
