---
doc-type: workflow
title: Prepare Assignment Workflow
purpose: workflow instruction for preparing ace-assign job configurations
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Prepare Assignment Workflow

## Purpose

Transform informal instructions OR preset names into a structured job.yaml file that can be used with `ace-assign create job.yaml`. This workflow bridges the gap between high-level intent and the structured work queue format.

## Input Formats

The workflow accepts three input types:

### 1. Preset Name Only

```
/as-assign-prepare work-on-task --taskref 123
```

Loads the preset and injects parameter values.

### 2. Informal Instructions Only

```
/as-assign-prepare "Work on task 123, create a PR, do 2 review cycles"
```

Transforms prose into structured steps.

### 3. Preset + Customization

```
/as-assign-prepare work-on-task --taskref 123 "skip onboarding, add security review"
```

Loads preset then applies modifications.

## Available Presets

Presets are stored in `ace-assign/.ace-defaults/assign/presets/`:

| Preset | Description |
|--------|-------------|
| `work-on-task` | Unified preset for single-task (`--taskref`) and batch (`--taskrefs`) execution |

List available presets:
```bash
ls ace-assign/.ace-defaults/assign/presets/
```

## Preset File Format

### Basic Preset

```yaml
name: preset-name
description: What this preset does

parameters:
  taskref:
    required: true
    description: Task reference (e.g., task-123 or 123)
  pr_number:
    required: false
    description: Optional PR number for review steps

steps:
  - name: step-name
    skill: ace_skill_name  # Optional skill reference
    instructions:
      - Step instruction line one.
      - "Step instruction with {{parameter}} placeholder."
```

### Preset with Expansion Directives

For multi-task presets, use the `expansion` section to generate hierarchical steps:

```yaml
name: work-on-task
description: Work on multiple tasks with consolidated review

parameters:
  taskrefs:
    required: true
    type: array  # Accepts comma-separated, range, or pattern
    description: Task references (e.g., "148,149,150" or "148-152")

expansion:
  batch-parent:
    name: batch-tasks
    number: "010"
    instructions: |
      Batch container - auto-completes when children done.
      Tasks: {{taskrefs}}

  foreach: taskrefs  # Parameter name to iterate over
  child-template:
    name: "work-on-{{item}}"  # {{item}} is current iteration value
    parent: "010"
    context: fork  # Parent split step can be forked (children stay non-fork)
    instructions: |
      Implement task {{item}} per specification.

steps:
  # Steps after expansion are appended with their own numbers
  - name: consolidated-review
    number: "020"
    instructions: Review all batch changes.
```

#### Array Parameter Syntax

The `--taskrefs` parameter accepts multiple formats:

| Format | Example | Result |
|--------|---------|--------|
| Comma-separated | `148,149,150` | Tasks 148, 149, 150 |
| Range | `148-152` | Tasks 148, 149, 150, 151, 152 |
| Pattern | `240.*` | All subtasks of 240 |

#### Generated Job Structure

For `--taskrefs 148,149,150`, expansion generates:

```
010 batch-tasks (parent, auto-completes)
├── 010.01 work-on-148 (fork context on split parent)
│   ├── 010.01.01 onboard (no fork marker)
│   ├── 010.01.02 plan-task (no fork marker)
│   └── 010.01.03 work-on-task (no fork marker)
├── 010.02 work-on-149 (fork context on split parent)
└── 010.03 work-on-150 (fork context on split parent)
020 consolidated-review
030 finalize
```

The hierarchical numbering enables:
- Parent auto-completion when all children are done
- Parent-only fork markers for subtree delegation
- Progress tracking per-task

## Parameter Placeholders

Use `{{parameter}}` syntax in preset instructions:
- `{{taskrefs}}` - Task references (single-item or multi-item list)
- `{{pr_number}}` - PR number (when available)

Parameters are injected when preparing the job.yaml.

## Transformation Rules

### From Informal Instructions

When parsing informal instructions, identify:

1. **Task References**: "task 123", "task-123", "#123"
2. **Skill Keywords**: Map to known skills
   - "work on task" → `ace:task-work`
   - "create pr", "make pr" → `ace:github-pr-create`
   - "review", "review pr" → `ace:review-pr`
   - "commit" → `ace:git-commit`
   - "onboard" → `onboard`
3. **Loop Indicators**: "2 cycles", "3 iterations", "twice"
4. **Sequence Markers**: "then", "after that", "finally"

### Loop Expansion

Review loops expand into forked cycle parent steps with standard child sub-steps:

```yaml
# "do 3 review cycles" becomes:
- name: review-valid-1
  context: fork
  sub_steps: [review-pr, apply-feedback, release]
  instructions:
    - "Child review-pr: use preset code-valid."
    - "Focus: correctness — bugs, logic errors, missing functionality, broken contracts."

- name: review-fit-1
  context: fork
  sub_steps: [review-pr, apply-feedback, release]
  instructions:
    - "Child review-pr: use preset code-fit."
    - "Focus: quality — performance, architecture, standards, test coverage."

- name: review-shine-1
  context: fork
  sub_steps: [review-pr, apply-feedback, release]
  instructions:
    - "Child review-pr: use preset code-shine."
    - "Focus: polish — simplification, naming, documentation (non-blocking suggestions)."
```

## Process Steps

### 1. Parse Input

Determine input type:
- If starts with known preset name → load preset
- If contains `--taskref` or similar flags → extract parameters
- If quoted string or prose → parse as informal instructions

### 2. Load Preset (if applicable)

```bash
# Read preset file
cat ace-assign/.ace-defaults/assign/presets/<preset-name>.yml
```

### 3. Extract Parameters

From command-line flags:
- `--taskref 123` → normalize to `taskrefs: ["123"]` (single task shorthand)
- `--taskrefs 148,149,150` → `taskrefs: ["148", "149", "150"]` (multi-task)
- `--taskrefs 148-152` → `taskrefs: ["148", "149", "150", "151", "152"]` (range)
- `--output custom-job.yaml` → output path

From informal instructions:
- "task 123" → `taskrefs: ["123"]`
- "tasks 148, 149, 150" → `taskrefs: ["148", "149", "150"]`
- "PR 45" → `pr_number: "45"`

### 3.1 Resolve Requested Taskrefs and Filter Terminal Tasks (`work-on-task` only)

Apply this step when preparing the `work-on-task` preset.

1. Resolve requested refs to concrete task refs first (before any filtering):
   - `--taskref` single value
   - comma-separated `--taskrefs`
   - ranges like `148-152`
   - patterns like `240.*`
2. For each resolved ref, run:

```bash
ace-task show <taskref>
```

3. Parse the reported status using `Ace::Task::Atoms::TaskValidationRules::TERMINAL_STATUSES` as the source of truth:
   - If status is terminal (`done`, `skipped`, `cancelled`) → add to `skipped_terminal_refs`
   - Otherwise (`pending`, `draft`, `in-progress`, `blocked`) → keep in `effective_taskrefs`
4. Preserve existing invalid-ref behavior:
   - If a ref cannot be resolved/found, fail with the existing invalid task reference path.
5. Branch by result:
   - Mixed set (`effective_taskrefs` non-empty, `skipped_terminal_refs` non-empty):
     - Continue with `effective_taskrefs`
     - Report skipped refs clearly (example: `Skipped terminal tasks (done/skipped/cancelled): 149`)
   - All-terminal set (`effective_taskrefs` empty, `skipped_terminal_refs` non-empty):
     - Stop before preset expansion and before job generation
     - Report:
       - `All requested tasks are already terminal (done/skipped/cancelled): <refs>`
       - `No assignment created.`

`effective_taskrefs` is now the source of truth for downstream expansion, hidden spec rendering, and mark-tasks-done behavior.

### 4. Apply Customizations (if prose provided)

Parse modifications:
- "skip onboarding" → remove onboard step
- "add security review" → insert security review step
- "only 2 cycles" → adjust loop count

### 5. Expand and Inject Parameters

For presets with `expansion` section, use `Ace::Assign::Atoms::PresetExpander.expand()`:

```ruby
require "ace/assign"

preset = YAML.load_file("work-on-task.yml")
params = { "taskrefs" => ["148", "149", "150"], "review_preset" => "batch" }
steps = Ace::Assign::Atoms::PresetExpander.expand(preset, params)
```

For `work-on-task`, pass `effective_taskrefs` from step 3.1 (not the unfiltered requested list).

### 5.1 Resolve Skill `assign.source` Metadata (Deterministic Runtime Expansion)

After preset expansion, each step with a `skill:` field may declare assignment source metadata via the skill frontmatter:

```yaml
assign:
  source: wfi://task/work
```

Resolution flow:
1. Find `SKILL.md` by step `skill` name (e.g., `ace:task-work`)
2. Read `assign.source` from skill frontmatter
3. Resolve `wfi://...` to workflow file
4. Parse workflow frontmatter `assign.sub-steps`
5. Materialize those sub-steps into the concrete job steps

This keeps lifecycle ownership in workflow files while prepare/create remain deterministic.
Compose intentionally does not perform this metadata scan.

This generates hierarchical steps with:
- Pre-assigned numbers (010, 010.01, 010.02, etc.)
- Parent-child relationships
- All `{{placeholder}}` tokens resolved

For standard presets (no expansion), replace `{{parameter}}` placeholders:

```yaml
# Before
instructions:
  - "Work on task {{taskref}}."

# After (with taskref=123)
instructions:
  - Work on task 123.
```

### 6. Validate Job Configuration

Check:
- [ ] Session name is set
- [ ] All required parameters have values
- [ ] No unresolved `{{placeholder}}` tokens remain
- [ ] Steps have names and instructions
- [ ] Skill references are valid (if present)

### 7. Generate job.yaml

Write the final configuration:

```yaml
session:
  name: <preset-name>-<taskref>
  description: <preset description with context>

steps:
  - name: <step-name>
    skill: <skill-reference>  # If present in preset
    instructions:
      - <resolved instruction line>
  # ... more steps
```

### 8. Output Result

Default output: `<task>/jobs/<timestamp>-job.yml` (e.g., `.ace-taskflow/v.0.9.0/tasks/229-xxx/jobs/k5abc123-job.yml`)

Custom output: Use `--output path/to/custom.yaml`

Report:
```
Job configuration created: job.yaml

Session: work-on-task-123
Steps: 10 total
  - onboard
  - work-on-task
  - create-pr
  - review-cycle-1
  - apply-feedback-1
  - review-cycle-2
  - apply-feedback-2
  - review-cycle-3
  - apply-feedback-3
  - finalize

Start assignment with: ace-assign create job.yaml
```

## Output Format

### job.yaml Structure

```yaml
session:
  name: work-on-task-123
  description: Work on task 123 with PR and review cycles

steps:
  - name: onboard
    skill: as-onboard
    instructions:
      - Onboard yourself to the codebase.
      - Load context and understand the project structure.

  - name: work-on-task
    skill: as-task-work
    instructions:
      - Work on task 123.
      - Implement the required changes following project conventions.

  - name: create-pr
    skill: as-github-pr-create
    instructions:
      - Create a pull request for the changes.
      - Capture the PR number for subsequent review steps.
      - Update the next steps with the PR number.

  # ... more steps
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Unknown preset | List available presets, ask for selection |
| Missing required parameter | Prompt for value |
| Invalid task reference | Show expected formats |
| Mixed refs include terminal tasks | Skip terminal refs, continue with remaining refs, and report skipped refs |
| All requested refs are terminal | Stop before expansion/job generation and report: `All requested tasks are already terminal (done/skipped/cancelled): ...` + `No assignment created.` |
| Unresolved placeholders | Report which parameters need values |

## Examples

### Example 1: Full Workflow Preset

```
/as-assign-prepare work-on-task --taskref 148
```

Creates job with 13 steps: onboard, work-on-task, release, create-pr, 2 review cycles (review + apply-feedback + release each), reorganize-commits, push-to-remote, update-pr-desc.

### Example 2: Informal Instructions

```
/as-assign-prepare "implement task 148, create pr, review twice"
```

Parses instructions and creates job with:
- onboard
- work-on-task (148)
- create-pr
- review-valid-1 (fork subtree: review-pr → apply-feedback → release)
- review-fit-1 (fork subtree: review-pr → apply-feedback → release)
- finalize

### Example 3: Custom Output Path

```
/as-assign-prepare work-on-task --taskref 148 --output .cache/my-job.yaml
```

Writes configuration to specified path.

### Example 4: Multi-Task Batch (Comma-Separated)

```
/as-assign-prepare work-on-task --taskrefs 148,149,150
```

Creates job with hierarchical structure:
- batch-tasks (010) - parent container
  - work-on-148 (010.01) - fork context
  - work-on-149 (010.02) - fork context
  - work-on-150 (010.03) - fork context
- consolidated-review (020)
- finalize (030)

### Example 5: Multi-Task Batch (Range)

```
/as-assign-prepare work-on-task --taskrefs 148-152
```

Expands range to tasks 148, 149, 150, 151, 152.

### Example 6: Multi-Task Batch (Pattern)

```
/as-assign-prepare work-on-task --taskrefs "240.*"
```

Expands pattern to match subtasks (requires resolution at prepare time).

### Example 7: Mixed Set with Terminal Tasks

```
/as-assign-prepare work-on-task --taskrefs 148,149,150
```

If `149` is terminal (for example `done`):
- continue with `148,150`
- report `Skipped terminal tasks (done/skipped/cancelled): 149`

### Example 8: All Requested Tasks Already Terminal

```
/as-assign-prepare work-on-task --taskrefs 148,149
```

If both are terminal:
- report `All requested tasks are already terminal (done/skipped/cancelled): 148,149`
- report `No assignment created.`
- do not generate a job.yaml

## Success Criteria

- [ ] Input correctly parsed (preset, parameters, or prose)
- [ ] Preset loaded and parameters injected
- [ ] Requested refs resolve to concrete task refs before any terminal-status filtering
- [ ] Terminal filtering uses `Ace::Task::Atoms::TaskValidationRules::TERMINAL_STATUSES`
- [ ] Mixed requested sets continue with non-terminal refs and report skipped terminal refs
- [ ] All-terminal requested sets stop before queue/job creation
- [ ] Expansion directives processed (if present)
- [ ] Hierarchical steps numbered correctly
- [ ] Loops expanded into separate steps
- [ ] All placeholders resolved
- [ ] Valid job.yaml generated
- [ ] Clear summary provided to user

## Next Steps

After job.yaml is created:

```bash
# Start the assignment
/as-assign-create job.yaml

# Or directly:
ace-assign create job.yaml

# Check status
ace-assign status

# Drive execution through the workflow
/as-assign-drive
```

**Note:** Job files created in `<task>/jobs/` stay in place when `ace-assign create` runs. Files created elsewhere are moved to `<task>/jobs/<session_id>-job.yml` for provenance. Always use `ace-assign status` to query the current assignment state.
