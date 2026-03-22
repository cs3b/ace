---
doc-type: workflow
title: Run In Batches Workflow
purpose: workflow instruction for reusable repeated-item orchestration with deterministic assignment creation
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Run In Batches Workflow

## Purpose

Create a reusable repeated-item assignment from:

1. One instruction template
2. One explicit `--items` list
3. Optional execution modifiers (`--sequential`, `--max-parallel`, `--run`)

This workflow keeps creation deterministic:

1. Render hidden spec under `.ace-local/assign/jobs/`
2. Call `ace-assign create <hidden-spec-path>`
3. Optionally hand off to `/as-assign-drive <assignment-id>`

## Supported Inputs

```bash
/as-assign-run-in-batches "Run E2E scenario {{item}}" --items TS-001,TS-002 --run
/as-assign-run-in-batches "Update docs for {{item}}" --items ace-assign,ace-task --sequential
/as-assign-run-in-batches "Review {{item}}" --items ace-git,ace-docs,ace-lint --max-parallel 3
```

## Runtime Boundary (Hard Rule)

`ace-assign create FILE` remains the deterministic runtime boundary.

- Parse and normalize workflow arguments in this workflow layer.
- Render a concrete hidden spec file.
- Pass the hidden spec file path to `ace-assign create`.
- Do not add natural-language parsing inside `ace-assign create`.

## Process

### 1. Parse Input

Required:
- One instruction template string (first positional argument)
- `--items <comma-separated-list>`

Optional:
- `--sequential` (run children one-by-one, still in fork context)
- `--max-parallel <N>` (parallel mode only, default: `3`; treated as rolling in-flight concurrency cap)
- `--run` (immediate handoff to `/as-assign-drive`)

If template or `--items` is missing, fail with an actionable message.

### 2. Normalize and Validate Item List

Normalize `--items` as:

1. Split by commas
2. Trim whitespace around each item
3. Drop empty entries
4. Preserve original order

Validation:
- If normalized list is empty → fail
- If duplicates exist after normalization → fail
- If `--max-parallel` is provided and is not an integer >= 1 → fail

Example failure messages:
- `--items is required (example: --items TS-001,TS-002)`
- `--items produced no valid values after normalization`
- `--items contains duplicates after normalization: TS-002`

### 3. Render Per-Item Instructions

For each normalized item:

- If template contains `{{item}}`, substitute with the item value.
- If template omits `{{item}}`, prepend a deterministic line:

```text
Target item: <item>
```

Then append the original template text unchanged.

### 4. Render Hidden Spec

Create hidden spec directory if missing:

```bash
mkdir -p .ace-local/assign/jobs
```

Write hidden spec:

```bash
.ace-local/assign/jobs/<timestamp>-run-in-batches.yml
```

Minimal structure:

```yaml
session:
  name: run-in-batches-<timestamp>
  description: Execute repeated-item assignment for explicit items.

steps:
  - number: "010"
    name: batch-items
    batch_parent: true
    parallel: true            # false when --sequential is set
    max_parallel: 3           # default 3 when parallel=true and flag omitted
    fork_retry_limit: 1
    instructions: |
      Batch container for repeated-item execution.
      Items: <item-1>, <item-2>, <item-3>
      Scheduler: parallel=true, max_parallel=3.

  - number: "010.01"
    name: run-<item-1>
    parent: "010"
    context: fork
    parallel: true            # mirrors parent mode; false when --sequential
    instructions: |
      <rendered instruction for item-1>

  - number: "010.02"
    name: run-<item-2>
    parent: "010"
    context: fork
    parallel: true            # mirrors parent mode; false when --sequential
    instructions: |
      <rendered instruction for item-2>
```

Rules:
- Always create one parent plus one child per item.
- A single item still creates a valid parent/child tree.
- Child steps always keep `context: fork` so every item is delegated in a forked environment.
- `--sequential` sets `parallel: false` and `max_parallel: 1` on parent/children.
- Parallel mode sets `parallel: true`; `max_parallel` is explicit or defaults to `3`.
- In parallel mode, `max_parallel` means maximum concurrent in-flight children; it is not a fixed wave size.
- Parent and child metadata are workflow-level scheduling hints consumed by `/as-assign-drive`.
- Each invocation writes a new hidden spec file.

### 5. Create Assignment Deterministically

Invoke:

```bash
ace-assign create .ace-local/assign/jobs/<timestamp>-run-in-batches.yml
```

### 6. Optional Immediate Handoff (`--run`)

If `--run` is present:

```bash
/as-assign-drive <assignment-id>
```

If no workable step is available, keep creation successful and report why drive did not continue.

### 7. Report Result

Show:
- Assignment ID and name
- Assignment path
- Hidden spec provenance path
- Whether drive handoff ran

## Error Handling

| Scenario | Action |
|----------|--------|
| Missing template | Fail with usage + example |
| Missing `--items` | Fail with actionable message |
| Empty normalized items | Fail; no assignment created |
| Duplicate normalized items | Fail; no assignment created |
| Invalid `--max-parallel` | Fail; no assignment created |
| Hidden-spec render failure | Fail with concrete error |
| `ace-assign create` rejection | Surface CLI error unchanged |
| `--run` requested but no workable step | Keep create success; report handoff reason |

## Edge Cases

- Template omits `{{item}}` → prepend deterministic `Target item:` line.
- Single-item list still uses parent + one child.
- `--sequential` keeps fork context and only changes scheduler metadata.
- Item normalization preserves order of first occurrences.

## Success Criteria

- `/as-assign-run-in-batches` accepts one template plus explicit `--items`
- Supports `--max-parallel` with default `3` when omitted in parallel mode
- Hidden spec is written under `.ace-local/assign/jobs/`
- Assignment has one parent plus one child step per item
- Child steps always include `context: fork`
- Parent/child metadata reflects scheduler intent (`parallel`, `max_parallel`, `fork_retry_limit`)
- `{{item}}` substitution and `Target item:` fallback are deterministic
- Optional `--run` handoff delegates to `/as-assign-drive`

## Verification

```bash
# Ensure new workflow exists and is discoverable
ace-bundle wfi://assign/run-in-batches
```
