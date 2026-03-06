# ace-compressor ACE-native source inputs - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compress an ACE preset directly

**Goal**: Run compressor on a preset without invoking `ace-bundle` first.

```bash
mise exec -- ace-compressor compress project --mode exact

# Expected output:
FILE|id=project|type=bundle_preset
P|id=fact:config_cascade|src=docs/architecture.md#configuration-cascade
```

### Scenario 2: Compress a workflow protocol per source

**Goal**: Resolve protocol-backed sources and keep outputs separated.

```bash
mise exec -- ace-compressor compress wfi://task/draft --mode compact --source-scope per-source

# Expected output:
FILE|id=wfi://task/draft|type=workflow
SUMMARY|source=wfi://task/draft|mode=compact
```

### Scenario 3: Fail clearly on unresolved ACE-native input

**Goal**: Identify the bad source without hiding which resolution step failed.

```bash
mise exec -- ace-compressor compress unknown-preset --mode exact

# Expected output:
Error: could not resolve input source 'unknown-preset'
```

## Notes for Implementer
- `merged` is the default source scope.
- ACE-native inputs are handled by `ace-compressor` directly.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
