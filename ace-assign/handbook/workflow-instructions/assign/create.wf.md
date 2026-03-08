---
name: assign/create
allowed-tools: Bash, Read, Write, AskUserQuestion
description: Public assignment creation workflow with optional handoff to drive
doc-type: workflow
purpose: workflow instruction for smart public create UX that renders hidden specs and calls deterministic ace-assign create
argument-hint: "[instructions|preset|job.yaml [params] [--run]]"

update:
  frequency: on-change
  last-updated: '2026-03-08'
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
- Continue to hidden-spec rendering (step 4)

#### Path C: Explicit Step or Freeform Intent (Default)

For explicit or natural-language requests:
- Run `wfi://assign/compose` to resolve phases from catalog data
- Preserve explicit user-requested steps as primary intent
- Keep catalog defaults and conditionals advisory unless a hard ordering/prerequisite rule applies

### 3. Resolve Explicit Steps (Path C)

For explicit-step requests (for example `run tests, reorganize commits, push to remote`):
- Resolve each phrase to one catalog phase using phase intent hints
- Normalize duplicates (same phase requested multiple times -> one phase, unless repetition is explicit)
- Preserve user order first
- Apply only hard ordering/prerequisite corrections and report each correction with the named rule

For unmatched phrases:
- Fail with actionable output that includes:
  - the unmatched phrase
  - closest phase/skill candidates

Skill-backed phases (for example `work-on-task`) stay high-level in rendered YAML.
Runtime `ace-assign create` will materialize `assign.source` sub-phases deterministically.

### 4. Render Hidden Spec (Paths B/C)

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
  - name: <phase-name>
    skill: <skill-if-present>
    instructions:
      - <instruction line>
```

Rules:
- Each invocation writes a new file (no in-place mutation of prior hidden specs).
- Hidden specs are internal provenance artifacts; users are not required to edit them.

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

If no workable phase exists, keep creation successful and report why drive cannot continue.

### 7. Report Result

Display assignment summary plus hidden-spec provenance (for Paths B/C):

```text
Assignment: <name> (<id>)
Created: .ace-local/assign/<id>/
Created from hidden spec: .ace-local/assign/jobs/<timestamp>-<assignment-slug>.yml

Phase 010: ...
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Unknown explicit phrase | Return unmatched phrase + closest catalog/skill candidates; no assignment created |
| Conflicting explicit order | Reorder only by hard rule and report the named rule that required it |
| Hidden-spec render failure | Return concrete render error; no assignment created |
| `ace-assign create` rejection | Surface CLI error unchanged |
| `--run` requested but no workable phase | Keep create success; report why drive did not continue |

## Edge Cases

- Re-running the same request creates a new hidden spec file.
- Explicit duplicate steps are normalized unless repetition is clearly requested.
- Explicit steps take precedence over recipe defaults when both are present.
- High-level skill-backed phases may expand into sub-phases at create runtime via `assign.source` metadata.
- `--run` is a workflow-level create-then-drive handoff, not natural-language parsing in `ace-assign create`.
- Quiet mode for `ace-assign create` suppresses non-essential output (including provenance line).

## Success Criteria

- Hidden spec is written under `.ace-local/assign/jobs/` for generated inputs
- `ace-assign create FILE` receives the rendered spec path
- Assignment metadata preserves hidden-spec provenance
- Explicit step requests map to expected phases with explainable ordering
- Skill-backed phases still expand through runtime `assign.source` metadata
- `--run` (when requested) triggers drive handoff as the final workflow step

## Verification

```bash
# Validate intent-resolution language exists in create workflow
rg -n "explicit|phrase|advisory|assign.source|--run" ace-assign/handbook/workflow-instructions/assign/create.wf.md

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
