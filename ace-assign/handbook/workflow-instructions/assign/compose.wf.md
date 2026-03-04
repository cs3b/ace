---
name: assign/compose
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Compose a tailored assignment from phase catalog and composition rules
argument-hint: '"description of what you need" [--taskref value] [--taskrefs values]'
doc-type: workflow
purpose: LLM-driven composition of assignments using phase catalog as building blocks

update:
  frequency: on-change
  last-updated: '2026-02-13'
---

# Compose Assignment Workflow

## Purpose

Compose a tailored assignment by selecting phases from the catalog, applying composition rules, and optionally using recipes as starting points. Replaces mechanical preset expansion with intelligent, context-aware composition.

Boundary:
- Compose uses only ace-assign catalog data (phases, rules, recipes) and user intent.
- Compose does not read `assign:` frontmatter from external files.
- Metadata-driven sub-phase materialization is handled by prepare/create runtime.

## Input Formats

### 1. Natural Description

```
/ace-assign-compose "implement task 148 with PR and 2 reviews"
```

### 2. Recipe Reference

```
/ace-assign-compose implement-with-pr --taskref 148
```

### 3. Description with Parameters

```
/ace-assign-compose "fix the auth bug and review" --taskref 203
```

## Process

### 1. Load Catalog

Load the phase catalog, composition rules, and available recipes:

```
# Phase catalog directory — use Glob tool
Glob: ace-assign/.ace-defaults/assign/catalog/phases/*.phase.yml

# Composition rules — use Read tool
Read: ace-assign/.ace-defaults/assign/catalog/composition-rules.yml

# Available recipes — use Glob tool
Glob: ace-assign/.ace-defaults/assign/catalog/recipes/*.recipe.yml
```

Read each phase file to understand available building blocks:
- Phase name, skill reference, description
- Prerequisites (required/recommended/optional)
- Produces/consumes (artifact flow)
- Context preference (fork or null)
- Effort level and tags

### 2. Understand Intent

Parse the user's input to determine:

- **Goal**: What needs to be accomplished (implement, fix, review, research, etc.)
- **Scope**: Single task, multiple tasks, or open-ended
- **Quality level**: Quick implementation, standard with review, or thorough with multiple cycles
- **Task references**: Extract from `--taskref`, `--taskrefs`, or description text ("task 148", "#203")
- **Constraints**: Explicit requests to include/exclude phases ("skip onboard", "add security review")

### 3. Match Recipe (Optional)

Check if the intent matches an available recipe:

```
# Read recipe files to check matches — use Read tool on each
Read: ace-assign/.ace-defaults/assign/catalog/recipes/*.recipe.yml
```

Recipe matching criteria:
- Compare user description against recipe `matches` patterns
- If a recipe name is given directly, use that recipe
- Recipe serves as a **starting point**, not a rigid template

If a recipe matches:
- Load its phase sequence as the initial plan
- Apply recipe's `customization_hints` as context
- Resolve recipe parameters (taskref, review_cycles, etc.)

If no recipe matches:
- Build the phase sequence from scratch using the catalog

### 4. Compose Phases

Select phases from the catalog based on intent:

#### Phase Selection Guidelines

| Intent | Core Phases | Optional Phases |
|--------|------------|-----------------|
| Implement + PR | onboard, work-on-task, **verify-test-suite**, **verify-e2e**, release, **update-docs**, create-pr, review-pr, apply-feedback, release, reorganize-commits, push-to-remote, update-pr-desc | lint, security-audit |
| Quick implement | onboard, work-on-task, commit | verify-test-suite, **verify-e2e** |
| Fix bug + PR | onboard, work-on-task, verify-test-suite, **verify-e2e**, create-pr, review-pr, apply-feedback | fix-tests, **update-docs** |
| Research | onboard, research | create-retro |
| Batch tasks | onboard, batch-parent(work-on-task), **verify-test-suite**, **verify-e2e**, release, **update-docs**, create-pr, review-pr, apply-feedback, release, reorganize-commits, push-to-remote, update-pr-desc | |

> For forked `work-on-task` child trees generated from `wfi://task/work`, each subtree runs `verify-test` (package-only, profile-based, no full suite). Full-suite behavior is expected at assignment level via `verify-test-suite` where preset rules require it.
>
> **When to include `verify-test-suite`**: Include for any task that modifies `.rb` files. The step profiles tests and enforces performance budgets to catch slow tests (network calls, unstubbed I/O) before they ship. Skip only for documentation-only or config-only changes.
>
> **When to include `verify-e2e`**: Include when the task modifies CLI commands, public APIs, or user-facing behavior. Skip for internal-only refactoring, documentation-only changes, or packages with no E2E test scenarios.
>
> **When to include `update-docs`**: Include when CLI commands, flags, options, or public contracts change. Skip for internal refactoring, private method changes, or when docs were already updated inline during `work-on-task`.

#### Fork Context Onboarding

When a phase has `context: fork`, automatically prepend this instruction:
- "First: onboard yourself using /ace-onboard skill to load project context."

This ensures forked agents have project context loaded before executing their primary task.

#### Review Cycle Expansion

When review cycles are needed, expand them as forked cycle parent phases:
- Default: 3 cycles (from composition rules `review_cycles.default_count`)
- Each cycle parent has `context: fork` and `sub_phases: [review-pr, apply-feedback, release]`
- Use `preset_progression` from composition rules for review preset per cycle:
  - Cycle 1: preset `code-valid`
  - Cycle 2: preset `code-fit`
  - Cycle 3: preset `code-shine`
- Use `focus_progression` from composition rules for review focus per cycle:
  - Cycle 1: "Correctness: bugs, logic errors, missing functionality, broken contracts"
  - Cycle 2: "Quality: performance, architecture, standards, test coverage"
  - Cycle 3: "Polish: simplification, naming, documentation (non-blocking suggestions)"
- Each cycle parent instruction should include both the preset and focus for its `review-pr` child, e.g.:
  - "Child review-pr: use preset code-valid."
  - "Focus: correctness — bugs, logic errors, missing functionality, broken contracts."

#### Prerequisite Checking

For each selected phase, verify prerequisites from the catalog:
- **required** prerequisites must be in the selection
- **recommended** prerequisites should be suggested if missing
- **optional** prerequisites can be noted but not enforced

### 5. Validate

Run composition rules validation on the phase sequence:

#### Ordering Validation

Check that phase ordering satisfies all rules from `composition-rules.yml`:
- `onboard` must be first (if present)
- `create-pr` must come before `review-pr`
- `review-pr` must come before `apply-feedback`
- `work-on-task` must come before `create-pr`
- `work-on-task` must come before `release`
- `release` must come before `create-pr` (initial release)
- `reorganize-commits` must come before `push-to-remote`
- `push-to-remote` must come before `update-pr-desc`

#### Prerequisite Validation

Verify all required prerequisites are satisfied.

#### Pair Completeness

Check that paired phases are complete:
- `review-pr` should be paired with `apply-feedback`
- `verify-test-suite` + `fix-tests` pair is conditional (only if failures detected)

### 6. Present Plan

Show the proposed assignment to the user:

```
Proposed: <assignment-name>

Phases:
  010: onboard — Load project context
  020: work-on-task — Implement task 148 (fork)
  030: release — Initial version bump (minor)
  040: create-pr — Create pull request
  050: review-valid-1 — Forked cycle root (children: review-pr, apply-feedback, release)
  080: review-fit-1 — Forked cycle root (children: review-pr, apply-feedback, release)
  110: review-shine-1 — Forked cycle root (children: review-pr, apply-feedback, release)
  140: reorganize-commits — Clean up commit history
  150: push-to-remote — Push to remote
  160: update-pr-desc — Finalize PR description

Suggestions:
  [optional] Add verify-test-suite before create-pr
  [optional] Add lint after work-on-task
```

Include:
- Phase number, name, and brief description
- Context indicator (fork) where applicable
- Suggestions from composition rules
- Prerequisite warnings (if any recommended prerequisites are missing)

### 7. Refine

Use AskUserQuestion to let the user adjust the plan:

- **Accept as-is**: Proceed to generation
- **Add phase**: Insert a suggested or custom phase
- **Remove phase**: Drop a phase from the plan
- **Adjust review cycles**: Change the number of review iterations
- **Custom modification**: Describe a change in natural language

Re-validate after modifications.

### 8. Generate job.yaml

Produce the same job.yaml format used by `ace-assign create`:

```yaml
session:
  name: <assignment-name>
  description: <composed description>

steps:
  - name: onboard
    skill: ace-onboard
    instructions:
      - Onboard yourself to the codebase.
      - Load context and understand the project structure.

  - name: work-on-task
    skill: ace-task-work
    context: fork
    instructions:
      - "Work on task 148."
      - Implement the required changes following project conventions.

  # ... more phases
```

#### Phase-to-Step Mapping

For each selected phase, generate a step entry:
- `name`: From catalog phase name (with suffix for repeated phases like review-cycle-1)
- `name`: From catalog phase name (with cycle suffixes like `review-valid-1`, `review-fit-1`, `review-shine-1`)
- `skill`: From catalog `skill` field (if present)
- `context`: From catalog `context.default` (if set)
- `instructions`: Built from catalog description + task-specific context

#### Instruction Templates

When a recipe provides `instructions_template`, use it with parameter substitution.
Otherwise, build instructions from the phase catalog description and the user's intent.

#### Batch/Expansion Support

For multi-task assignments, use the same expansion format as existing presets:

```yaml
expansion:
  batch-parent:
    name: batch-tasks
    number: "010"
    instructions: "Batch container for tasks: {{taskrefs}}"
  foreach: taskrefs
  child-template:
    name: "work-on-{{item}}"
    parent: "010"
    context: fork
    skill: ace-task-work
    instructions: "Implement task {{item}}"
```

### 9. Output Result

Write job.yaml to the task's jobs directory (same location as prepare-assignment):

Default output: `<task>/jobs/<timestamp>-job.yml`
Custom output: Use `--output path/to/custom.yaml`

Report:
```
Assignment composed: <assignment-name>
Job configuration: <path-to-job.yaml>

Phases: N total
  010: onboard
  020: work-on-task
  ...

Composed from: <recipe-name> recipe (or "custom composition")
Composition validated: no ordering violations

Start assignment with: ace-assign create <job.yaml>
Or use: /ace-assign-create <job.yaml>
```

## Phase Metadata in Generated Steps

Steps can include optional metadata for the orchestrator's adaptive decision-making:

```yaml
- name: verify-test-suite
  instructions:
    - Run the test suite and report results.
  skip_if: "no code changes since last review"
  trigger_on_failure: fix-tests
  decision_notes: "Check if tests were already run"
```

These extra fields pass through to phase files via `PhaseWriter.create`'s `extra` parameter.

## Error Handling

| Scenario | Action |
|----------|--------|
| No matching recipe | Build from scratch using catalog |
| Missing required prerequisite | Add it automatically, inform user |
| Ordering violation | Reorder phases to satisfy rules |
| Unknown phase referenced | List available phases from catalog |
| Missing required parameter | Prompt user via AskUserQuestion |
| Empty phase selection | Suggest minimum viable assignment |

## Examples

### Example 1: Full Workflow from Description

```
/ace-assign-compose "implement task 148, create PR, review twice"
```

Matches `implement-with-pr` recipe. Generates:
- onboard, work-on-task(148), release, create-pr, (review-pr + apply-feedback + release)×2, reorganize-commits, push-to-remote, update-pr-desc

### Example 2: Simple Task

```
/ace-assign-compose "quickly implement task 200"
```

Matches `implement-simple` recipe. Generates:
- onboard, work-on-task(200), commit

### Example 3: Custom Composition

```
/ace-assign-compose "research auth patterns, then implement task 180 with security review"
```

No exact recipe match. Composed from catalog:
- onboard, research, work-on-task(180), security-audit, create-pr, review-pr, apply-feedback

### Example 4: Batch Tasks

```
/ace-assign-compose "work on tasks 148,149,150" --taskrefs 148,149,150
```

Matches `batch-tasks` recipe. Generates hierarchical structure.

## Success Criteria

- [ ] Phase catalog loaded and available for selection
- [ ] User intent correctly parsed
- [ ] Recipe matched when applicable
- [ ] Phase sequence satisfies ordering rules
- [ ] Prerequisites validated
- [ ] Review cycles expanded correctly
- [ ] job.yaml generated in backward-compatible format
- [ ] User had opportunity to refine the plan
- [ ] Clear summary provided

## Next Steps

After job.yaml is created:

```bash
# Create and start the assignment
/ace-assign-create <job.yaml>

# Or start driving immediately
/ace-assign-drive
```
