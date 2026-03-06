# ace-compressor compact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compact a narrative-heavy document

**Goal**: Reduce token footprint aggressively while keeping key concepts and rules.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode compact

# Expected output:
SUMMARY|ACE is a CLI-first toolkit for human+agent workflows
FACT|id=fact:ace:approach|value=[cli_tools,file_interchange,composable_workflows]
EXAMPLE_REF|id=ace_git_commit_usage
```

### Scenario 2: Refuse unsafe compaction

**Goal**: Stop before a rule-heavy source loses required semantics.

```bash
mise exec -- ace-compressor compress docs/decisions.md --mode compact

# Expected output:
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

## Notes for Implementer
- `compact` is the user-facing name for the lossy mode.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
