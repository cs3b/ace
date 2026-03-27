# Unified Preset Input for Create Command - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Create assignment from preset + task ref

**Goal**: Start a full work-on-task assignment without the prepare step

```bash
ace-assign create --task t.2p4.1 --preset work-on-task
```

#### Expected Output

```text
Assignment: work-on-task-t.2p4.1-job.yml (8qqgyk)
Created: .ace-local/assign/8qqgyk/

Step 000: onboard [in_progress]
Instructions: Load project context for the task batch: t.2p4.1.
```

### Scenario 2: Create assignment with default preset

**Goal**: Preset defaults to `work-on-task` when omitted

```bash
ace-assign create --task t.r6b
```

#### Expected Output

```text
Assignment: work-on-task-t.r6b-job.yml (abc123)
Created: .ace-local/assign/abc123/
Steps: 17 total

Step 000: onboard [in_progress]
```

### Scenario 3: Create from YAML file

**Goal**: Existing flow using explicit file path

```bash
ace-assign create --yaml .ace-local/assign/jobs/custom-job.yml
```

#### Expected Output

```text
Assignment: custom-job.yml (def456)
Created: .ace-local/assign/def456/

Step 010: first-step [in_progress]
```

### Scenario 4: Terminal task rejected

**Goal**: Task already done is rejected before creating assignment

```bash
ace-assign create --task t.2p4.0
```

#### Expected Output

```text
Error: Task t.2p4.0 is already terminal (done). No assignment created.
```

### Scenario 5: Missing input mode

**Goal**: No flags provided

```bash
ace-assign create
```

#### Expected Output

```text
Error: Exactly one of --yaml or --task is required
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- This task's contract mirrors `add`'s option-only design: positional CONFIG is removed
