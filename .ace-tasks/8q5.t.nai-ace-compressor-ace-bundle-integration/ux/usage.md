# ace-compressor ace-bundle integration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compress a bundle preset as one merged pack

**Goal**: Use an existing ACE preset without running `ace-bundle` separately.

```bash
mise exec -- ace-compressor compress project --mode exact

# Expected output:
FILE|id=project|type=bundle_preset
SUMMARY|merged sources compressed into one ContextPack
P|id=fact:...|src=docs/vision.md#core-principles
```

### Scenario 2: Compress each resolved source separately from a protocol URL

**Goal**: Keep source outputs separate for agent loading and later patching.

```bash
mise exec -- ace-compressor compress wfi://task/draft --mode compact --source-scope per-source

# Expected output:
FILE|id=wfi://task/draft|type=workflow
SUMMARY|per-source compression output
P|id=rule:...|src=ace-task/handbook/workflow-instructions/task/draft.wf.md#goal
```

## Notes for Implementer
- `merged` is the default source scope.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
