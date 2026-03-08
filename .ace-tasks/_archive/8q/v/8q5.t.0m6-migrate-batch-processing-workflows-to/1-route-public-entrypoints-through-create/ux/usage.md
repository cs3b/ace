# Public Create and Drive - Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Normal public creation

**Goal**: Create an assignment using the only supported public creation skill.

```bash
/as-assign-create "work on task 123 and create a PR"

# Expected output:
# Assignment created
# User is told to continue with /as-assign-drive
```

### Scenario 2: Create and begin immediately

**Goal**: Skip the extra drive step when explicitly requested.

```bash
/as-assign-create "work on task 123 and create a PR" --run

# Expected output:
# Assignment created
# Drive workflow starts immediately as the last create step
```

### Scenario 3: Explicit create then drive

**Goal**: Keep the default two-step path when users want a pause between creation and execution.

```bash
/as-assign-create work-on-task --taskref 123
/as-assign-drive
```

### Scenario 4: Advanced CLI escape hatch

**Goal**: Use deterministic file-driven create directly for hand-authored/debug specs.

```bash
ace-assign create .ace-local/assign/jobs/manual-job.yml
```

This remains supported as a lower-level path, but it is not the primary public UX.

## Error and Edge Handling

- If stale docs reference `/as-assign-prepare` or `/as-assign-start` as public entrypoints, update them to create+drive guidance.
- If `--run` is requested but the created assignment has no workable phase, creation still succeeds and reports why drive did not continue.
- `--run` is workflow-level behavior (`create` handing off to `drive`), not natural-language behavior inside raw `ace-assign create`.
