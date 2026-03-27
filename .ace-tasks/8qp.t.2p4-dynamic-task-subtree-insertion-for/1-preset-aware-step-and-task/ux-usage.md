# Preset-Aware Step and Task Insertion - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Retry a failed review cycle

**Goal**: Re-add a review-fit step tree after the previous one failed

```bash
ace-assign add --step review-fit
```

#### Expected Output

```text
Added review-fit-2 (3 step(s)) after 100
  101: review-fit-2 [pending] (fork)
  101.01: review-pr [pending]
  101.02: apply-feedback [pending]
  101.03: release [pending]
```

### Scenario 2: Add a full review sequence

**Goal**: Insert valid + fit + shine review cycles in one command

```bash
ace-assign add --step review-valid,review-fit,review-shine --after 100
```

#### Expected Output

```text
Added 3 step tree(s) after 100
  101: review-valid-2 [pending] (fork)
  101.01: review-pr [pending]
  101.02: apply-feedback [pending]
  101.03: release [pending]
  102: review-fit-2 [pending] (fork)
  102.01: review-pr [pending]
  102.02: apply-feedback [pending]
  102.03: release [pending]
  103: review-shine-2 [pending] (fork)
  103.01: review-pr [pending]
  103.02: apply-feedback [pending]
  103.03: release [pending]
```

### Scenario 3: Add a new task to a running batch

**Goal**: Insert a task subtree into the batch parent of an active assignment

```bash
ace-assign add --task t.456
```

#### Expected Output

```text
Added task t.456 under 010
  010.03: work-on-t.456 [pending] (fork)
```

### Scenario 4: Step name not found in preset

**Goal**: User types a step name that doesn't exist

```bash
ace-assign add --step review-deep
```

#### Expected Output

```text
Error: Step 'review-deep' not found in preset 'work-on-task'.
Available steps: onboard, verify-test-suite, verify-e2e, release-minor, update-docs,
  create-pr, review-valid, review-fit, review-shine, reorganize-commits, push-to-remote,
  record-demo, update-pr-desc, mark-tasks-done, create-retro
```

### Scenario 5: YAML batch insertion uses the canonical file flag

**Goal**: Insert a concrete subtree from a YAML file

```bash
ace-assign add --yaml steps.yml --after 010 --child
```

#### Expected Output

```text
Added 4 step(s) from steps.yml
  010.03: work-on-t.456 [pending]
  010.03.01: onboard [pending]
  010.03.02: plan-task [pending]
  010.03.03: work-on-task [pending]
```

### Scenario 6: Missing insertion mode is rejected

**Goal**: User runs `add` without saying what to insert

```bash
ace-assign add
```

#### Expected Output

```text
Error: Exactly one of --yaml, --step, or --task is required
```

### Scenario 7: Mutually exclusive flags

**Goal**: User combines incompatible flags

```bash
ace-assign add --yaml steps.yml --step review-fit
```

#### Expected Output

```text
Error: --yaml, --step, and --task are mutually exclusive
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- This task's contract is option-only: positional `name` insertion and `--from` are intentionally removed
