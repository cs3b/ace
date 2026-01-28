---
name: coworker-prepare-job
allowed-tools: Bash, Read, Write
description: Prepare job.yaml from preset or informal instructions
argument-hint: "[preset-name] [--taskref value] [--output path]"
doc-type: workflow
purpose: workflow instruction for ace-coworker job preparation

update:
  frequency: on-change
  last-updated: '2026-01-28'
---

# Coworker Prepare Job Workflow

## Purpose

Transform informal instructions OR preset names into a structured job.yaml file that can be used with `ace-coworker start --config job.yaml`. This workflow bridges the gap between high-level intent and the structured work queue format.

## Input Formats

The workflow accepts three input types:

### 1. Preset Name Only

```
/ace:coworker-prepare work-on-task-with-pr --taskref 123
```

Loads the preset and injects parameter values.

### 2. Informal Instructions Only

```
/ace:coworker-prepare "Work on task 123, create a PR, do 2 review cycles"
```

Transforms prose into structured steps.

### 3. Preset + Customization

```
/ace:coworker-prepare work-on-task-with-pr --taskref 123 "skip onboarding, add security review"
```

Loads preset then applies modifications.

## Available Presets

Presets are stored in `ace-coworker/.ace-defaults/coworker/presets/`:

| Preset | Description |
|--------|-------------|
| `work-on-task` | Simple task implementation with commit |
| `work-on-task-with-pr` | Full workflow with PR and 3 review cycles |

List available presets:
```bash
ls ace-coworker/.ace-defaults/coworker/presets/
```

## Preset File Format

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
    skill: ace:skill-name  # Optional skill reference
    instructions: |
      Step instructions with {{parameter}} placeholders.
```

## Parameter Placeholders

Use `{{parameter}}` syntax in preset instructions:
- `{{taskref}}` - Task reference
- `{{pr_number}}` - PR number (when available)

Parameters are injected when preparing the job.yaml.

## Transformation Rules

### From Informal Instructions

When parsing informal instructions, identify:

1. **Task References**: "task 123", "task-123", "#123"
2. **Skill Keywords**: Map to known skills
   - "work on task" → `ace:work-on-task`
   - "create pr", "make pr" → `ace:create-pr`
   - "review", "review pr" → `ace:review-pr`
   - "commit" → `ace:commit`
   - "onboard" → `onboard`
3. **Loop Indicators**: "2 cycles", "3 iterations", "twice"
4. **Sequence Markers**: "then", "after that", "finally"

### Loop Expansion

Loops must be fully expanded into separate steps:

```yaml
# "do 3 review cycles" becomes:
- name: review-cycle-1
  skill: ace:review-pr
  instructions: Review (iteration 1 of 3)...

- name: apply-feedback-1
  instructions: Apply feedback from review...

- name: review-cycle-2
  skill: ace:review-pr
  instructions: Review (iteration 2 of 3)...

- name: apply-feedback-2
  instructions: Apply feedback from review...

- name: review-cycle-3
  skill: ace:review-pr
  instructions: Review (iteration 3 of 3)...

- name: apply-feedback-3
  instructions: Apply final feedback...
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
cat ace-coworker/.ace-defaults/coworker/presets/<preset-name>.yml
```

### 3. Extract Parameters

From command-line flags:
- `--taskref 123` → `taskref: "123"`
- `--output custom-job.yaml` → output path

From informal instructions:
- "task 123" → `taskref: "123"`
- "PR 45" → `pr_number: "45"`

### 4. Apply Customizations (if prose provided)

Parse modifications:
- "skip onboarding" → remove onboard step
- "add security review" → insert security review step
- "only 2 cycles" → adjust loop count

### 5. Inject Parameters

Replace all `{{parameter}}` placeholders in instructions:

```yaml
# Before
instructions: Work on task {{taskref}}.

# After (with taskref=123)
instructions: Work on task 123.
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
    instructions: |
      <resolved instructions>
  # ... more steps
```

### 8. Output Result

Default output: `job.yaml` in current directory

Custom output: Use `--output path/to/custom.yaml`

Report:
```
Job configuration created: job.yaml

Session: work-on-task-with-pr-123
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

Start session with: ace-coworker start --config job.yaml
```

## Output Format

### job.yaml Structure

```yaml
session:
  name: work-on-task-with-pr-123
  description: Work on task 123 with PR and review cycles

steps:
  - name: onboard
    skill: onboard
    instructions: |
      Onboard yourself to the codebase.
      Load context and understand the project structure.

  - name: work-on-task
    skill: ace:work-on-task
    instructions: |
      Work on task 123.
      Implement the required changes following project conventions.

  - name: create-pr
    skill: ace:create-pr
    instructions: |
      Create a pull request for the changes.
      Capture the PR number for subsequent review steps.
      Update the next steps with the PR number.

  # ... more steps
```

## Error Handling

| Scenario | Action |
|----------|--------|
| Unknown preset | List available presets, ask for selection |
| Missing required parameter | Prompt for value |
| Invalid task reference | Show expected formats |
| Unresolved placeholders | Report which parameters need values |

## Examples

### Example 1: Preset with Parameter

```
/ace:coworker-prepare work-on-task --taskref 148
```

Creates simple job with 3 steps: onboard, work-on-task, finalize.

### Example 2: Full Workflow Preset

```
/ace:coworker-prepare work-on-task-with-pr --taskref 148
```

Creates job with 10 steps including PR and 3 review cycles.

### Example 3: Informal Instructions

```
/ace:coworker-prepare "implement task 148, create pr, review twice"
```

Parses instructions and creates job with:
- onboard
- work-on-task (148)
- create-pr
- review-cycle-1, apply-feedback-1
- review-cycle-2, apply-feedback-2
- finalize

### Example 4: Custom Output Path

```
/ace:coworker-prepare work-on-task-with-pr --taskref 148 --output .cache/my-job.yaml
```

Writes configuration to specified path.

## Success Criteria

- [ ] Input correctly parsed (preset, parameters, or prose)
- [ ] Preset loaded and parameters injected
- [ ] Loops expanded into separate steps
- [ ] All placeholders resolved
- [ ] Valid job.yaml generated
- [ ] Clear summary provided to user

## Next Steps

After job.yaml is created:

```bash
# Start the session
ace-coworker start --config job.yaml

# Check status
ace-coworker status

# Work through steps following the session workflow
```
