# ace-compressor stable updates and patches - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Emit stable IDs in exact output

**Goal**: Produce exact output that can be compared across runs.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode exact --verbose

# Expected output:
FILE|id=file:docs/vision.md|type=vision
SECTION|id=sec:core_principles|title=Core Principles
RULE|id=rule:cli_first|modality=must|action=be developer friendly
```

### Scenario 2: Emit a delta patch for one changed file

**Goal**: Refresh one changed source without resending the whole pack.

```bash
mise exec -- ace-compressor patch prev.contextpack docs/vision.md --mode exact

# Expected output:
PATCH|base=sha256:abc123
R|id=rule:cli_first|value=tools must be developer friendly
```

## Notes for Implementer
- This phase starts patching with exact-mode single-file updates.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
