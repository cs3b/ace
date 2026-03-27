# Multi-Backend Recording - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Default Recording (asciinema)

**Goal**: Record a tape.yml demo using asciinema as the default backend for YAML tapes

```bash
ace-demo record my-tape
```

#### Expected Output

```
Recording my-tape (asciinema)...
  Cast: .ace-local/demo/my-tape.cast
  Converting to GIF via agg...
  Output: .ace-local/demo/my-tape.gif
  Verification: PASS (3/3 commands found)
```

### Scenario 2: Explicit VHS Backend for WebM

**Goal**: Keep WebM support through the compatibility backend

```bash
ace-demo record my-tape --backend vhs --format webm
```

#### Expected Output

```
Recording my-tape (vhs, webm)...
  Output: .ace-local/demo/my-tape.webm
```

### Scenario 3: Attach a Cast File to a PR

**Goal**: Use the recorded `.cast` as input and let `attach` perform the conversion/upload flow

```bash
ace-demo attach .ace-local/demo/my-tape.cast --pr 123
```

#### Expected Output

```
Preparing .ace-local/demo/my-tape.cast for PR #123...
  Converting cast to GIF via agg...
  Uploaded: my-tape-1700000000.gif
  Posted demo comment to PR #123
```

### Scenario 4: Unsupported Format on Default Backend

**Goal**: Fail fast when a format requires the VHS compatibility path

```bash
ace-demo record my-tape --format webm
```

#### Expected Output

```
Error: Format 'webm' requires --backend vhs when recording YAML tapes
```

### Scenario 5: Unsupported MP4 Format

**Goal**: Reject removed `mp4` support with actionable guidance

```bash
ace-demo record my-tape --format mp4
```

#### Expected Output

```
Error: Unsupported format: mp4. Use gif, or use --backend vhs --format webm for compatibility output.
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
