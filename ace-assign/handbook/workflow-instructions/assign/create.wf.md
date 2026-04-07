---
doc-type: workflow
title: Create Assignment Workflow
purpose: workflow instruction for smart public create UX that renders hidden specs and calls deterministic ace-assign create
ace-docs:
  last-updated: 2026-04-07
  last-checked: 2026-03-21
---

# Create Assignment Workflow

## Purpose

Create assignments through one public entrypoint while preserving deterministic runtime behavior:

1. Resolve user intent (preset, explicit steps, or high-level request)
2. Render a normalized hidden spec under `.ace-local/assign/jobs/`
3. Call `ace-assign create <hidden-spec-path>`
4. Optionally hand off to `/as-assign-drive` when `--run` is requested

Public UX:
- `/as-assign-create ...` creates an assignment
- `/as-assign-create ... --run` creates then immediately hands off to `/as-assign-drive`

## Supported Inputs

```bash
# Preset-style input
/as-assign-create work-on-task --taskref 123

# Explicit requested steps
/as-assign-create "run tests, reorganize commits, push to remote"

# High-level skill-backed intent
/as-assign-create "work on task 123 and create a PR"

# Existing job file passthrough
/as-assign-create path/to/job.yaml
```

## Runtime Boundary (Hard Rule)

`ace-assign create FILE` remains the deterministic runtime boundary.

- This workflow may parse user intent and render YAML.
- The CLI create command must still ingest a concrete file path.
- Do not add natural-language parsing inside `ace-assign create`.

## Process

### 1. Parse Input and Flags

Extract:
- Primary input payload (preset name, freeform text, or file path)
- Parameters (`--taskref`, `--taskrefs`, `--output`, etc.)
- `--run` flag (create-then-drive handoff)

Normalize freeform input for intent matching:
- lowercase
- trim whitespace
- split explicit step lists on commas and "and then"

### 2. Select Creation Path

Choose exactly one path:

#### Path A: Existing Job File

If input is an existing `.yml`/`.yaml` file path:
- Use it directly as create input
- Skip hidden-spec rendering

#### Path B: Preset/Recipe Input

If input is an exact preset/recipe-style request (for example `work-on-task --taskref 123`):
- Run `wfi://assign/prepare` to produce normalized job content
- If prepare reports all requested refs are already terminal (`done/skipped/cancelled`), stop and return that no assignment was created
- Otherwise continue to hidden-spec rendering (step 4) using the filtered ref set from prepare

#### Path C: Explicit Step or Freeform Intent (Default)

For explicit or natural-language requests:
- Run `wfi://assign/compose` to resolve steps from canonical assign-capable skill data
- Preserve explicit user-requested steps as primary intent
- Keep catalog defaults and conditionals advisory unless a hard ordering/prerequisite rule applies

### 3. Resolve Explicit Steps (Path C)

For explicit-step requests (for example `run tests, reorganize commits, push to remote`):
- Resolve each phrase to one catalog step using step intent hints
- Canonical step source excludes capability skills; only assign-capable workflow/orchestration entries are eligible
- Normalize duplicates (same step requested multiple times -> one step, unless repetition is explicit)
- Preserve user order first
- Apply only hard ordering/prerequisite corrections and report each correction with the named rule

For unmatched phrases:
- Fail with actionable output that includes:
  - the unmatched phrase
  - closest step/skill candidates

Skill-backed steps (for example `work-on-task`) stay high-level in rendered YAML.
Runtime `ace-assign create` will materialize `assign.source` sub-steps deterministically.

### 4. Render Hidden Spec (Paths B/C with Workable Input)

Precondition:
- Path B: prepare returned workable, filtered content (not an all-terminal abort)
- Path C: compose resolved at least one actionable step

Create hidden spec directory if missing:

```bash
mkdir -p .ace-local/assign/jobs
```

Render normalized YAML to a timestamped file:

```bash
.ace-local/assign/jobs/<timestamp>-<assignment-slug>.yml
```

Required structure:

```yaml
session:
  name: <assignment-name>
  description: <assignment-description>

steps:
  - name: <step-name>
    source: <source-ref-skill-or-wfi>
    instructions:
      - <instruction line>
```

`instructions` are assignment overlay only. The reusable execution body comes from the canonical source resolution during `ace-assign create`.

Rules:
- Each invocation writes a new file (no in-place mutation of prior hidden specs).
- Hidden specs are internal provenance artifacts; users are not required to edit them.
- Do not render a hidden spec for all-terminal `work-on-task` requests that aborted in Path B.

### 5. Create Assignment Deterministically

Invoke CLI boundary:

```bash
ace-assign create .ace-local/assign/jobs/<timestamp>-<assignment-slug>.yml
```

### 6. Optional Immediate Handoff (`--run`)

If `--run` is present, hand off to drive as the last step:

```bash
/as-assign-drive <assignment-id>
```

`/as-assign-drive` is a run-until-complete-or-blocked handoff, not a one-step progress check. Once handed off, it should keep driving until the assignment is actually complete or reaches an explicit blocker/failure stop condition.

If no workable step exists, keep creation successful and report why drive cannot continue.

### 7. Report Result

Display assignment summary plus hidden-spec provenance (for Paths B/C):

```text
Assignment: <name> (<id>)
Created: .ace-local/assign/<id>/
Created from hidden spec: .ace-local/assign/jobs/<timestamp>-<assignment-slug>.yml

Step 010: ...
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Unknown explicit phrase | Return unmatched phrase + closest catalog/skill candidates; no assignment created |
| Conflicting explicit order | Reorder only by hard rule and report the named rule that required it |
| Path B all requested refs already terminal | Return clear no-op result (`All requested tasks are already terminal (done/skipped/cancelled): ...`, `No assignment created.`); skip hidden-spec render and `ace-assign create` |
| Hidden-spec render failure | Return concrete render error; no assignment created |
| `ace-assign create` rejection | Surface CLI error unchanged |
| `--run` requested but no workable step | Keep create success; report why drive did not continue |

## Edge Cases

- Re-running the same request creates a new hidden spec file.
- Explicit duplicate steps are normalized unless repetition is clearly requested.
- Explicit steps take precedence over recipe defaults when both are present.
- Path B mixed refs (terminal + non-terminal) continue with filtered non-terminal refs only.
- Path B all-terminal refs produce no assignment and no hidden-spec artifact.
- High-level skill-backed steps may expand into sub-steps at create runtime via `assign.source` metadata.
- `--run` is a workflow-level create-then-drive handoff, not natural-language parsing in `ace-assign create`.
- Quiet mode for `ace-assign create` suppresses non-essential output (including provenance line).

## Success Criteria

- Hidden spec is written under `.ace-local/assign/jobs/` for generated inputs
- `ace-assign create FILE` receives the rendered spec path
- Path B all-terminal requests do not render a hidden spec and do not call `ace-assign create`
- Path B mixed requests render/create from filtered non-terminal refs only
- Assignment metadata preserves hidden-spec provenance
- Explicit step requests map to expected steps with explainable ordering
- Capability skills remain excluded from assign composition
- Skill-backed steps still expand through runtime `assign.source` metadata
- `--run` (when requested) triggers drive handoff as the final workflow step
- Drive handoff semantics are run-until-complete-or-blocked, not stop-after-first-progress

## Verification

```bash
# Validate intent-resolution language exists in create workflow
rg -n "explicit|phrase|advisory|assign.source|--run|already terminal|No assignment created" ace-assign/handbook/workflow-instructions/assign/create.wf.md

# Validate hidden-spec references remain present
rg -n "\.ace-local/assign/jobs|Created from hidden spec" ace-assign

# Validate package behavior
ace-test ace-assign
```

## Next Steps

After assignment creation:

```bash
/as-assign-drive <assignment-id>
```
