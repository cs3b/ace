# ace-compressor exact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compress one Markdown file exactly

**Goal**: Run the first vertical slice of the package on a single source.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode exact

# Expected output:
FILE|id=docs/vision.md|type=vision
SECTION|id=sec:overview|title=Overview
RULE|id=rule:cli_first|modality=must|action=be developer friendly
```

### Scenario 2: Compress a directory of docs exactly

**Goal**: Produce one merged exact pack with per-source provenance.

```bash
mise exec -- ace-compressor compress docs/ --mode exact --verbose

# Expected output:
FILE|id=docs/vision.md|type=vision
FILE|id=docs/architecture.md|type=architecture
P|id=fact:config_cascade|src=docs/architecture.md#configuration-cascade
```

## Notes for Implementer
- `exact` is the user-facing name for the lossless mode.
- This phase targets stdio output only.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
