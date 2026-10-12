# Close Retro to Harness Edit Loop - Draft Usage

## API Surface

- [x] CLI (`ace-retro link`, `ace-retro status` extension)
- [ ] Developer API
- [ ] Agent API (skills flow unchanged; CLI-backed)
- [ ] Configuration (none expected)

## Usage Scenarios

### Scenario 1: Link a harness finding to an edit task

**Goal**: Track that a workflow failure found in a retro is being fixed by a specific task.

```bash
ace-retro link f3k9x2 --task 8xb.t.k3v.2
```

Expected output:

```text
Linked finding f3k9x2 -> task 8xb.t.k3v.2 (verification: failing E2E scenario recorded)
```

### Scenario 2: View open improvement debt

**Goal**: See harness-class findings that have no linked edit task.

```bash
ace-retro status
```

Expected output:

```text
Harness findings: 4 total, 2 linked, 2 open debt
Open debt:
  - a1b2c3 (workflow: git-commit, failure: doc lint loop)
```

### Scenario 3 (Error): Link to unknown id

**Goal**: Invalid finding id fails clearly.

```bash
ace-retro link nope99 --task 8xb.t.k3v.2
```

Expected output:

```text
Error: finding 'nope99' not found. Run ace-retro list to see finding ids.
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`.
