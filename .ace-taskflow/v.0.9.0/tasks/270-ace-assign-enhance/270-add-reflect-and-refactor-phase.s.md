---
id: v.0.9.0+task.270
status: draft
priority: medium
estimate: 4h
dependencies: []
---

# Add reflect-and-refactor phase to ace-assign

## Behavioral Specification

### User Experience

A developer or agent completes `work-on-task` and tests pass. Before creating a PR, the `reflect-and-refactor` phase runs automatically (or is invoked manually):

1. **Analyze** — Reviews the diff (staged changes since assignment start) using an architecture-focused ace-review preset, checking ATOM compliance, over-engineering, missing abstractions
2. **Decide** — Produces a short findings report: what to refactor, what's fine, what to skip
3. **Refactor** — Executes bounded refactoring (single iteration, capped scope) based on findings
4. **Commit** — Commits refactoring changes separately from implementation commits

### Expected Behavior

The phase bridges the gap between implementation and PR creation. Currently, after `work-on-task` succeeds and tests pass, assignments jump straight to mark-done/release/PR — missing an opportunity for the agent to self-assess against ATOM architecture principles and simplify before shipping.

Existing mechanisms are insufficient:
- **`create-retro`** captures lessons but takes no refactoring action
- **Review cycles** (`code-valid` → `code-fit` → `code-shine`) review PR diffs after PR creation, not before
- **`code-fit` preset** includes architecture analysis but is a review preset, not a refactor trigger

The `reflect-and-refactor` phase fills this gap: it **analyzes implementation against ATOM principles and executes targeted refactoring** before code reaches the PR stage.

### Success Criteria

- [ ] Phase file `reflect-and-refactor.phase.yml` exists in the phase catalog
- [ ] Phase leverages `ace-review` with a new or composed preset (e.g., `architecture-reflection` building on `ruby-atom` + `code-fit`)
- [ ] Composition rules updated with ordering and pairing rules
- [ ] Recipe `implement-with-pr.recipe.yml` updated to include the phase
- [ ] Single iteration only — no recursive reflection loops
- [ ] Phase is configurable: can be skipped for trivial tasks
- [ ] Demo gate step defined with skip condition and failure behavior
- [ ] Re-plan mechanism specified with single-recursion cap and sub-task limit (max 1–2)
- [ ] `create-retro` phase updated to consume `findings-report` with recommended prerequisite on `reflect-and-refactor`

## Objective

Add a `reflect-and-refactor` phase to the ace-assign phase catalog that runs between implementation and PR creation. The phase analyzes the diff against ATOM principles and executes bounded refactoring to improve code quality before shipping.

## Scope of Work

### Phase Definition

Create `reflect-and-refactor.phase.yml` in `ace-assign/.ace-defaults/assign/catalog/phases/`:

```yaml
name: reflect-and-refactor
skill: null  # or new skill TBD
description: Analyze implementation against ATOM principles and execute targeted refactoring

prerequisites:
  - name: work-on-task
    strength: required
    reason: "Must have implementation to reflect on"
  - name: verify-test-suite
    strength: required
    reason: "Tests must pass before reflection — refactoring a broken build wastes effort"

produces: [refactoring-commits, findings-report]
consumes: [code-changes, test-results]

context:
  default: null
  reason: "Reflection needs access to full diff and project context"

when_to_skip:
  - "Assignment was trivial (e.g., docs-only, config change)"
  - "No substantive code changes to analyze"
  - "Explicitly skipped in assignment configuration"

effort: light
tags: [quality, architecture, reflection]
```

### Review Preset

Create or compose an `architecture-reflection` preset for `ace-review` that combines:
- ATOM architecture compliance checks (from `ruby-atom` preset / `atom.md` focus prompt)
- Over-engineering detection (unnecessary abstractions, premature generalization)
- Missing abstractions (repeated patterns that should be extracted)
- Code-fit quality checks (architecture section)

The preset should produce a structured findings report with:
- **Refactor** items (actionable, bounded)
- **Accept** items (correct as-is)
- **Skip** items (out of scope or too risky)

### Composition Rules Updates

Add to `ace-assign/.ace-defaults/assign/catalog/composition-rules.yml`:

```yaml
# Ordering rules
- rule: reflect-after-verify
  before: verify-test-suite
  after: reflect-and-refactor
  note: "Reflection requires passing tests as baseline"

- rule: reflect-before-mark-done
  before: reflect-and-refactor
  after: mark-task-done
  note: "Refactoring should complete before marking task done"

- rule: reflect-before-release
  before: reflect-and-refactor
  after: release
  note: "Refactoring should complete before version release"

# Pairs
- name: reflect-verify-cycle
  phases: [reflect-and-refactor, verify-test-suite]
  pattern: sequential
  note: "Re-verify after refactoring to catch regressions"

- name: reflect-fix-cycle
  phases: [reflect-and-refactor, fix-tests]
  pattern: conditional
  trigger: "re-verification after refactoring finds failures"

- name: reflect-replan-cycle
  phases: [reflect-and-refactor, work-on-task]
  pattern: conditional
  trigger: "demo validation failure or fundamental architectural misalignment"
  cap: 1
  note: "Re-plan produces 1-2 sub-tasks, then reflect runs once more (no further re-plan)"

# Ordering rules (retro integration)
- rule: reflect-before-retro
  before: reflect-and-refactor
  after: create-retro
  note: "Findings report feeds into retrospective as structured input"

# Conditional suggestion
- when: "assignment includes work-on-task"
  suggest: [reflect-and-refactor]
  strength: optional
  note: "Architecture reflection before shipping — skip for trivial tasks"
```

### Recipe Update

Update `implement-with-pr.recipe.yml` to include the phase:

```yaml
phases:
  - name: onboard
  - name: plan-task
  - name: work-on-task
  - name: verify-test-suite        # existing
  - name: reflect-and-refactor     # NEW — after verify, before mark-done
    required: false
    note: "Architecture reflection — skip for trivial tasks"
  - name: mark-task-done
  - name: release
  - name: create-pr
  - name: review-cycle
  # ... rest unchanged
```

### Lifecycle Position

**Single-task assignment:**
```
work-on-task → verify-test-suite → reflect-and-refactor → verify-test-suite → [fix-tests if needed] → mark-task-done → release → create-pr
```

**Batch/multi-task assignment (runs per task):**
```
work-on-task(1) → verify → reflect-and-refactor → verify → [fix-tests]
work-on-task(2) → verify → reflect-and-refactor → verify → [fix-tests]
...
mark-task-done → release → create-pr
```

### Key Behaviors

- **Per-task**: Reflection runs after EACH `work-on-task`, not once at the end
- **Re-verification**: Full test suite run after refactoring to catch regressions
- **Fix loop**: If re-verification finds failures → `fix-tests` phase inserted → re-verify again
- **Single iteration**: Reflection itself runs once per task (no recursive reflection)
- **Bounded**: The reflect→verify→fix cycle runs at most once (reflect once, fix if broken, move on)

### Functional Demo Gate

Before architecture analysis, the reflect-and-refactor phase optionally runs a functional demo/validation step proving the feature works end-to-end (beyond just tests passing).

- **Position**: `demo-validation` becomes step 1 in the phase; the existing `analyze` step shifts to step 2
- **Mechanism**: Uses `ace-test` E2E tests or custom demo scripts defined in assignment configuration
- **Skip condition**: When `verify-test-suite` already covers functional validation adequately (e.g., E2E tests exist and passed in the verify phase)
- **Failure behavior**: If demo validation fails, triggers the re-plan mechanism (see below) rather than proceeding to architecture analysis

Updated phase steps become:
1. **Demo-validate** (optional) — Run functional demo proving the feature works end-to-end
2. **Analyze** — Review diff using architecture-focused ace-review preset
3. **Decide** — Produce findings report: refactor / accept / skip
4. **Refactor** — Execute bounded refactoring based on findings
5. **Commit** — Commit refactoring changes separately

### Re-plan on Failure

If the reflect-and-refactor phase identifies fundamental issues (not cosmetic refactoring), it can trigger a bounded re-plan: generating new sub-tasks or a revised approach.

- **Trigger**: Demo validation failure OR architecture analysis finds structural misalignment (not just style issues)
- **Distinguished from `fix-tests`**: `fix-tests` handles test failures; re-plan handles architectural misalignment requiring rework
- **Bounded**: Re-plan happens at most once per reflect-and-refactor invocation
- **Output**: Produces at most 1–2 follow-up sub-tasks added to the current assignment
- **After re-plan**: The follow-up sub-tasks execute, then reflect-and-refactor runs again (but cannot trigger another re-plan — single recursion cap)

### Improve `create-retro` Phase Integration

The reflect-and-refactor findings report should feed into `create-retro` as structured input, connecting the "what would you do differently" question to the existing retrospective mechanism.

- **Prerequisite**: Add `reflect-and-refactor` as an optional prerequisite to `create-retro.phase.yml` (strength: recommended)
- **Artifact flow**: `create-retro` consumes the `findings-report` artifact produced by `reflect-and-refactor`
- **Retro content**: The findings report provides concrete architectural observations that inform the retro's "lessons learned" and "what would you do differently" sections
- **No duplication**: This replaces the need for a separate reflection/post-mortem mechanism — the existing `create-retro` phase handles it with richer input

Changes to `create-retro.phase.yml`:
```yaml
prerequisites:
  - name: reflect-and-refactor
    strength: recommended
    reason: "Findings report enriches retrospective with architectural observations"

consumes: [findings-report]  # Added — from reflect-and-refactor
```

### Deliverables

#### Create
- `ace-assign/.ace-defaults/assign/catalog/phases/reflect-and-refactor.phase.yml`
- New or composed `ace-review` preset for architecture reflection (exact location TBD)

#### Modify
- `ace-assign/.ace-defaults/assign/catalog/composition-rules.yml` — add ordering, pairs, conditional rules
- `ace-assign/.ace-defaults/assign/catalog/recipes/implement-with-pr.recipe.yml` — insert phase
- `ace-assign/.ace-defaults/assign/catalog/phases/create-retro.phase.yml` — add prerequisite and consumes

## Implementation Notes

### Source Ideas
- `8pey8n-ace-assign-refactor/introduce-reflection-and-refactor-phase.idea.s.md` — original reflect-and-refactor concept
- `8pey7b-assign-feat/add-validation-and-retrospective-loops.idea.s.md` — demo gate, re-plan on failure, retro integration

### Related Patterns
- `create-retro.phase.yml` — documentation-only reflection (no action)
- `code-fit` review preset — architecture review after PR (not before)
- `ruby-atom` review preset — ATOM compliance checking
- `atom.md` focus prompt — ATOM architecture analysis prompt

### Open Questions
- Should the `architecture-reflection` preset be a standalone preset or a composition of existing presets?
- Should the phase have its own skill (e.g., `ace:reflect-and-refactor`) or reuse `ace-review` directly?
- What is the right default: optional or recommended in the conditional suggestion?
- ~~Should reflect-and-refactor feed into create-retro?~~ **Resolved**: Yes — findings-report consumed by create-retro as recommended prerequisite
