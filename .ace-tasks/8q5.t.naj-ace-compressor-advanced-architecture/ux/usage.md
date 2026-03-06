# ace-compressor advanced architecture - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Consume stable ContextPack records

**Goal**: Give agents a deterministic, provenance-aware compressed document shape.

```text
FILE|id=docs/vision.md|type=vision
RULE|id=rule:cli_first|modality=must|action=be developer friendly
P|id=rule:cli_first|src=docs/vision.md#core-principles
```

### Scenario 2: Apply incremental PatchPack updates

**Goal**: Refresh changed units without resending the entire pack.

```text
PATCH|base=sha256:abc123
R|id=rule:cli_first|value=tools must be developer friendly
I|after=fact:config_cascade|id=fact:new_flag|value=env_override
```

## Notes for Implementer
- This task is spec-only and defines contracts for later implementation.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
