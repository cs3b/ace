# ace-compressor exact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compress one document exactly

**Goal**: Preserve rules and numerics while reducing prompt size.

```bash
mise exec -- ace-compressor compress docs/architecture.md --mode exact

# Expected output:
FILE|id=docs/architecture.md|type=architecture
RULE|id=rule:cli_framework|modality=must|action=use dry-cli
FACT|id=fact:config_cascade|value=[cli,project,user,defaults]
```

### Scenario 2: Surface unresolved chart content without guessing

**Goal**: Keep the command successful while making non-text gaps explicit.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode exact

# Expected output:
C|id=chart:vision:01|status=unresolved|reason=image_only_reference
P|id=chart:vision:01|src=docs/vision.md#chart-reference
```

## Notes for Implementer
- `exact` is the user-facing name for the lossless mode.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
