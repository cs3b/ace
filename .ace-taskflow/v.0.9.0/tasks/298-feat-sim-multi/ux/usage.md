# Multi-File Input Support for ace-sim - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Comma-separated source files

**Goal**: Validate a parent task spec together with its subtask spec in a single simulation run

```bash
ace-sim run --preset validate-task --source "path/to/parent.s.md,path/to/subtask.s.md"

# Expected output:
# Run Dir: /tmp/ace-sim/runs/...
# [chain execution output]
# input.bundle.md created in run directory with both files merged
```

### Scenario 2: Glob pattern source

**Goal**: Validate all task specs under an orchestrator directory

```bash
ace-sim run --preset validate-task --source "tasks/291/**/*.s.md"

# Expected output:
# Run Dir: /tmp/ace-sim/runs/...
# [chain execution output]
# input.bundle.md created with all matching files merged
```

### Scenario 3: Writeback rejected for multi-file source

**Goal**: Prevent ambiguous writeback when source resolves to multiple files

```bash
ace-sim run --preset validate-task --source "parent.s.md,subtask.s.md" --writeback

# Expected output (non-zero exit):
# Error: writeback requires a single source file
```

### Scenario 4: Missing file in comma list

**Goal**: Fail early with a clear error when a listed file does not exist

```bash
ace-sim run --preset validate-task --source "exists.md,missing.md"

# Expected output (non-zero exit):
# Error: source file not found: missing.md
```

### Scenario 5: Empty glob matches

**Goal**: Fail early when glob pattern matches no files

```bash
ace-sim run --preset validate-task --source "nonexistent/**/*.md"

# Expected output (non-zero exit):
# Error: no files matched source pattern: nonexistent/**/*.md
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
- Single file `--source` also routes through ace-bundle for uniform behavior
- `input.bundle.md` is always the step-1 input regardless of file count
