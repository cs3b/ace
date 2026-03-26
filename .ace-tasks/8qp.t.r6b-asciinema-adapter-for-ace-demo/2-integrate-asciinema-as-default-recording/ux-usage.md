# Multi-Backend Recording - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Default Recording (asciinema)

**Goal**: Record a tape.yml demo using asciinema as the default backend

```bash
ace-demo record my-tape
```

#### Expected Output

```
Recording my-tape (asciinema)...
  Cast: .ace-local/demo/my-tape.cast
  Converting to gif via agg...
  Output: .ace-local/demo/my-tape.gif
  Verification: PASS (3/3 commands verified)
```

### Scenario 2: Explicit VHS Backend

**Goal**: Use VHS for backward-compatible recording

```bash
ace-demo record my-tape --backend vhs
```

#### Expected Output

```
Recording my-tape (vhs)...
  Output: .ace-local/demo/my-tape.gif
```

### Scenario 3: Invalid Backend

**Goal**: Clear error when unknown backend specified

```bash
ace-demo record my-tape --backend foo
```

#### Expected Output

```
Error: Unknown backend 'foo'. Valid backends: asciinema, vhs
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
