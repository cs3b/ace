# Smart Create and Generic Fan-out - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Create an assignment from intent

**Goal**: Start work without authoring a visible `job.yaml`.

```bash
/as-assign-create "work on task 123, create a PR, review twice"

# Expected output:
# Assignment created from a hidden spec under .ace-local/assign/jobs/
# First phase is shown and the user can continue with /as-assign-drive
```

### Scenario 2: Create and immediately drive

**Goal**: Skip the extra manual drive command when the user explicitly asks to start now.

```bash
/as-assign-create work-on-task --taskref 123 --run

# Expected output:
# Assignment is created, then the drive workflow starts using that assignment
```

### Scenario 3: Run repeated work through generic fan-out

**Goal**: Replace bespoke batch wrappers with one reusable assign entrypoint.

```bash
/as-assign-run-in-batches "Run E2E scenario {{item}}" --items TS-001,TS-002 --run

# Expected output:
# Parent/child assignment created
# Child items fork by default
# Drive begins immediately because --run was requested
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
